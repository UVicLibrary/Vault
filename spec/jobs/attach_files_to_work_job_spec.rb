# frozen_string_literal: true
RSpec.describe AttachFilesToWorkJob, perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let(:uploaded_file1) { build(:uploaded_file, file: file1) }
  let(:uploaded_file2) { build(:uploaded_file, file: file2) }
  let(:user) { create(:user) }
  let(:user2) { create(:user, display_name: 'userz@bbb.ddd') }
  let(:generic_work) { create(:public_generic_work) }

  context "when use_valkyrie is false" do

    shared_examples 'a file attacher', perform_enqueued: [described_class, IngestJob] do

      it 'attaches files, copies visibility and permissions and updates the uploaded files' do
        described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
        # perform_enqueued configuration in spec_helper doesn't seem to work
        # so we perform them inline here instead
        enqueued_jobs.select { |hash| hash[:job] == IngestJob }.each do |job|
          wrapper_id = job[:args].first.values.first.split('/').last.to_i
          IngestJob.perform_now(JobIoWrapper.find(wrapper_id))
        end
        generic_work.reload

        expect(CharacterizeJob).to have_been_enqueued.at_least(:twice)
        expect(generic_work.file_sets.count).to eq 2
        expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
        expect(uploaded_file1.reload.file_set_uri).not_to be_nil
        expect(ImportUrlJob).not_to have_been_enqueued
      end
    end

    context "with uploaded files on the filesystem" do

      it_behaves_like 'a file attacher' do

        it 'records the depositor(s) in edit_users' do
          expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor]))
        end

        describe 'with existing files' do
          let(:file_set)       { create(:file_set) }
          let(:uploaded_file1) { build(:uploaded_file, file: file1, file_set_uri: 'http://example.com/file_set') }

          before do
            allow(FileSet).to receive(:find).with(any_args).and_call_original
            allow(FileSet).to receive(:find).with('file_set').and_return(file_set)
            allow(file_set).to receive(:parent).and_return(generic_work)
          end

          it 'skips files that already have a FileSet and are attached to the work' do
            expect { described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2]) }
              .to change { generic_work.file_sets.count }.to eq 1
          end

          context 'when a file already has a FileSet that is *not* attached to the work' do

            before do
              allow(file_set).to receive(:parent).and_return(nil)
            end

            it 'attaches the existing FileSet without creating a new one' do
              described_class.perform_now(generic_work, [uploaded_file1])
              expect(generic_work.file_sets).to contain_exactly(file_set)
              expect(FileSet.all.count).to eq 1
            end
          end

        end
      end
    end

    context "with uploaded files at remote URLs" do
      let(:url1) { 'https://example.com/my/img.png' }
      let(:url2) { URI('https://example.com/other/img.png') }
      let(:fog_file1) { double(CarrierWave::Storage::Abstract, url: url1) }
      let(:fog_file2) { double(CarrierWave::Storage::Abstract, url: url2) }

      before do
        allow(uploaded_file1.file).to receive(:file).and_return(fog_file1)
        allow(uploaded_file2.file).to receive(:file).and_return(fog_file2)
      end

      it_behaves_like 'a file attacher'
    end

    context "deposited on behalf of another user" do
      before do
        generic_work.on_behalf_of = user.user_key
        generic_work.save
      end
      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([user.user_key]))
        end
      end
    end

    context "deposited as 'Yourself' selected in on behalf of list" do
      before do
        generic_work.on_behalf_of = ''
        generic_work.save
      end
      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor]))
        end
      end
    end
  end

  context "when use_valkyrie is true" do

    let(:generic_work) { valkyrie_create(:hyrax_work, :public, title: ['BethsMac'], depositor: user.user_key) }

    before do
      allow(uploaded_file1).to receive(:user).and_return(user)
      allow(uploaded_file2).to receive(:user).and_return(user)
      # Silence many, many "already initialized constant" warnings
      $VERBOSE=nil
    end

    after do
      $VERBOSE=true
    end

    shared_examples 'a file attacher', perform_enqueued: [described_class, IngestJob] do

      it 'attaches files, copies visibility and permissions and updates the uploaded files' do
        described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
        # perform_enqueued configuration in spec_helper doesn't seem to work
        # so we perform them inline here instead
        enqueued_jobs.select { |hash| hash[:job] == IngestJob || hash[:job] == ValkyrieIngestJob }.each do |job|
          job_class = job[:job]
          args_id = job[:args].first.values.first.split('/').last.to_i
          args_class = job[:job] == IngestJob ? JobIoWrapper : Hyrax::UploadedFile

          job_class.perform_now(args_class.find(args_id))
        end

        id = generic_work.id

        if generic_work.class == GenericWork
          expect(CharacterizeJob).to have_been_enqueued.at_least(:twice)
        else
          expect(ValkyrieCreateDerivativesJob).to have_been_enqueued.at_least(:twice)
        end

        generic_work = Hyrax.query_service.find_by(id: id)
        file_sets = Hyrax.custom_queries.find_child_filesets(resource: generic_work)
        expect(file_sets.count).to eq 2
        expect(file_sets.map(&:visibility)).to all(eq 'open')
        expect(uploaded_file1.reload.file_set_uri).not_to be_nil
        expect(ImportUrlJob).not_to have_been_enqueued
      end
    end

    context "with uploaded files on the filesystem" do
      before do
        Hyrax::AccessControlList.new(resource: generic_work).grant(:edit).to(user2).save
      end
      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          file_sets = Hyrax.custom_queries.find_child_filesets(resource: generic_work)
          expect(file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor, 'userz@bbb.ddd']))
        end

        describe 'with existing files' do
          let(:file_set)       { create(:file_set) }
          let(:uploaded_file1) { build(:uploaded_file, file: file1, file_set_uri: 'http://example.com/file_set') }

          it 'skips files that already have a FileSet' do
            id = generic_work.id
            expect(Hyrax.custom_queries.find_child_filesets(resource: generic_work).count).to eq 0
            described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
            generic_work = Hyrax.query_service.find_by(id: id)
            expect(Hyrax.custom_queries.find_child_filesets(resource: generic_work).count).to eq 1
          end
        end
      end
    end

    context "with uploaded files at remote URLs" do
      let(:url1) { 'https://example.com/my/img.png' }
      let(:url2) { URI('https://example.com/other/img.png') }
      let(:fog_file1) { double(CarrierWave::Storage::Abstract, url: url1) }
      let(:fog_file2) { double(CarrierWave::Storage::Abstract, url: url2) }

      before do
        allow(uploaded_file1.file).to receive(:file).and_return(fog_file1)
        allow(uploaded_file2.file).to receive(:file).and_return(fog_file2)
      end

      it_behaves_like 'a file attacher'
    end

    context "deposited on behalf of another user" do
      before do
        generic_work.on_behalf_of = user.user_key
        generic_work.permission_manager.acl.save
      end

      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          file_sets = Hyrax.custom_queries.find_child_filesets(resource: generic_work)

          expect(file_sets.map(&:edit_users)).to all(match_array([user.user_key]))
        end
      end
    end

    context "deposited as 'Yourself' selected in on behalf of list" do
      before do
        generic_work.on_behalf_of = ''
        generic_work.permission_manager.acl.save
      end

      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          file_sets = Hyrax.custom_queries.find_child_filesets(resource: generic_work)

          expect(file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor]))
        end
      end
    end
  end
end