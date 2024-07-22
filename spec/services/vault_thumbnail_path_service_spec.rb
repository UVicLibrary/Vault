RSpec.describe VaultThumbnailPathService do
  include Hyrax::FactoryHelpers

  subject { described_class.call(object) }

  context "with a FileSet" do

    before { allow(ActiveFedora::Base).to receive(:find).with('999').and_return(object) }

    before do
      allow(ActiveFedora::Base).to receive(:find).with('999').and_return(object)
      allow(object).to receive(:original_file).and_return(original_file)
      # https://github.com/samvera/active_fedora/issues/1251
      allow(object).to receive(:persisted?).and_return(true)
    end

    let(:object) { build(:file_set, id: '999') }

    context "that has an image thumbnail" do
      before do
        allow(ActiveFedora::Base).to receive(:find).with('999').and_return(object)
        allow(object).to receive(:original_file).and_return(original_file)
        allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(original_file).and_return("#{object.id}/files/#{original_file.id}")
      end

      let(:original_file)  { mock_file_factory(mime_type: 'image/jpeg') }

      before { allow(File).to receive(:exist?).and_return(true) }
      it { is_expected.to eq "/images/999%2Ffiles%2F#{original_file.id}/full/!150,300/0/default.jpg" }
    end

    context "that has no thumbnail" do
      let(:original_file) { mock_file_factory(mime_type: nil) }

      it { is_expected.to match %r{/assets/work-.+.png} }
    end
  end

  context "with a Work" do

    let(:object)         { GenericWork.new(thumbnail_id: representative.id) }
    let(:representative) { FileSet.new(id: '999') }
    let(:collection) { Collection.new(id: "foo-bar", title: ["Collection Title"]) }

    context "that doesn't have a representative" do
      let(:object) { FileSet.new }
      let(:original_file)  { nil }

      it { is_expected.to match %r{/assets/default-.+.png} }
    end

    context "that has an image thumbnail" do

      before do
        allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
        allow(representative).to receive(:original_file).and_return(original_file)
        allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(original_file).and_return(original_file.id)
      end

      let(:original_file)  { mock_file_factory(mime_type: 'image/jpeg') }

      it { is_expected.to eq "/images/#{original_file.id}/full/!150,300/0/default.jpg" }

      context "and has more than one version" do

        before { allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(original_file).and_return("#{original_file.id}/fcr:versions/version2") }

        it "returns the path to the latest version" do
          expect(subject).to eq "/images/#{original_file.id}%2Ffcr:versions%2Fversion2/full/!150,300/0/default.jpg"
        end

      end
    end

    context "with an audio thumbnail" do

      before do
        allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
        allow(representative).to receive(:parent).and_return(object)
        allow(object).to receive(:member_of_collection_ids).and_return([collection.id])
        allow(ActiveFedora::Base).to receive(:find).with(collection.id).and_return(collection)
      end

      before do
        allow(representative).to receive(:audio?).and_return true
      end

      context "and is not in any collection" do
        before { allow(representative).to receive(:parent).and_return nil }

        it { is_expected.to match %r{audio(.+)?\.png} }
      end

      context "and is in a collection" do
        it { is_expected.to match %r{collection(.+)?\.png} }
      end

      context "that is an m4a file" do
        let(:representative) { create(:file_set, id: "999") }
        let(:file) { Hydra::PCDM::File.new }
        before do
          allow(representative).to receive(:files).and_return([file])
          allow(representative.files.first).to receive(:original_name).and_return("foo.m4a")
        end

        it "returns the same result as for an audio thumbnail" do
          expect(subject).to match %r{collection(.+)?\.png}
        end
      end
    end

    context "and has a pdf thumbnail" do

      before do
        allow(ActiveFedora::Base).to receive(:find).with("999").and_return(representative)
        allow(representative).to receive(:pdf?).and_return true
      end

      it { is_expected.to eq("/pdf_thumbnails/999-thumb.jpg") }
    end

    context "and has a video thumbnail" do

      before do
        allow(representative).to receive(:video?).and_return true
        allow(ActiveFedora::Base).to receive(:find).with("999").and_return(representative)
        allow(File).to receive(:exist?).with(Hyrax::DerivativePath.derivative_path_for_reference(representative, 'thumbnail')).and_return true
      end

      it { is_expected.to eq("/downloads/999?file=thumbnail") }
    end

    context 'with a Hyrax::FileSet' do

      before { allow(Hyrax.config).to receive(:use_valkyrie?).and_return true }

      context "with an image thumbnail" do
        let(:representative) { FactoryBot.create(:file_set, :with_original_file) }

        it "includes the version in the URL" do
          expect(subject).to eq "/images/#{CGI.escape("#{representative.original_file.id}/fcr:versions/version1").gsub("%3A",":")}/full/!150,300/0/default.jpg"
        end
      end

      context 'with an audio thumbnail' do
        before do
          allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
          allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:audio?).and_return true
        end

        context "and is not in any collection" do
          it { is_expected.to match %r{audio(.+)?\.png} }
        end

        context "and is in a collection" do
          let(:collection) { Collection.new(id: "foo-bar", title: ["Collection Title"]) }

          # Set up associations
          before do
            object.member_of_collections = [collection]
            allow(Hyrax.custom_queries).to receive(:find_parent_work).and_return(object)
            allow(ActiveFedora::Base).to receive(:find).with(collection.id).and_return(collection)
            allow(CollectionThumbnailPathService).to receive(:call).and_call_original
          end

          it 'returns the collection thumbnail' do
            expect(CollectionThumbnailPathService).to receive(:call).with(collection)
            expect(subject).to match %r{collection(.+)?\.png}
          end
        end
      end

      context 'with a video thumbnail' do
        let(:original_file) { mock_file_factory(mime_type: 'video/mp4') }
        let(:file_metadata) { FactoryBot.build(:hyrax_file_metadata, mime_type: 'video/mp4') }

        before do
          allow(File).to receive(:exist?).and_call_original
          allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
          allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:video?).and_return true
          allow(File).to receive(:exist?).with(Hyrax::DerivativePath.derivative_path_for_reference(representative, 'thumbnail')).and_return true
          allow(Hyrax.custom_queries).to receive(:find_file_metadata_by)
                                             .with(id: Valkyrie::ID.new(original_file.id))
                                             .and_return(file_metadata)
        end

        it { is_expected.to eq("/downloads/999?file=thumbnail") }

      end


      context 'with an m4a file' do
        let(:original_file) { mock_file_factory(original_filename: 'smthg.m4a') }
        let(:file_metadata) { FactoryBot.build(:hyrax_file_metadata, original_filename: 'smthg.m4a') }

        before do
          allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
          allow(representative).to receive(:original_file).and_return(original_file)
          allow(Hyrax.custom_queries).to receive(:find_file_metadata_by)
                                             .with(id: Valkyrie::ID.new(original_file.id))
                                             .and_return(file_metadata)
        end

        it { is_expected.to match %r{audio(.+)?\.png} }
      end

      context 'with a pdf thumbnail' do
        before do
          allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
          allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:pdf?).and_return true
        end

        it { is_expected.to eq "/pdf_thumbnails/999-thumb.jpg" }
      end

    end
  end



end
