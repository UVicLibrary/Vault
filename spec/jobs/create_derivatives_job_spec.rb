# frozen_string_literal: true
RSpec.describe CreateDerivativesJob do
  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end

  context "filepath parameter" do
    let(:file_set) { create(:file_set) }

    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'world.png'))
        f.original_name = 'world.png'
        f.mime_type = 'image/png'
      end
    end

    before do
      file_set.original_file = file
      file_set.save!
    end

    describe 'with valid filepath param' do
      let(:filename) { File.join(fixture_path, 'world.png') }

      it 'skips Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory' do
        expect(Hyrax::WorkingDirectory).not_to receive(:copy_repository_resource_to_working_directory)
        expect_any_instance_of(VipsDerivativesService).to receive(:create_image_derivatives)
        described_class.perform_now(file_set, file.id, filename)
      end
    end

    describe 'with no filepath param' do
      let(:filename) { nil }

      it 'Uses Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory to pull the repo file' do
        expect(Hyrax::WorkingDirectory).to receive(:copy_repository_resource_to_working_directory)
        expect_any_instance_of(VipsDerivativesService).to receive(:create_image_derivatives)
        described_class.perform_now(file_set, file.id, filename)
      end
    end
  end

  context "with an audio file" do
    let(:id)       { '123' }
    let(:file_set) { FileSet.new }

    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = 'picture.png'
        f.save!
      end
    end

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:id).and_return(id)
      allow(file_set).to receive(:mime_type).and_return('audio/x-wav')
    end

    context "with a file name" do
      it 'calls create_derivatives and save on a file set' do
        expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        described_class.perform_now(file_set, file.id)
      end
    end

    context 'with a parent object' do
      let(:parent) { GenericWork.new(create_date: Time.zone.parse('2014-01-02 12:00:00').iso8601) }

      before do
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
      end

      context 'when the file_set is the thumbnail of the parent' do
        let(:parent) { GenericWork.new(thumbnail_id: id, create_date: Time.zone.parse('2014-01-02 12:00:00').iso8601) }

        it 'updates the index of the parent object' do
          expect(file_set).to receive(:reload)
          expect(parent).to receive(:save)
          described_class.perform_now(file_set, file.id)
        end
      end

      context "when the file_set isn't the parent's thumbnail" do

        it "doesn't update the parent's index" do
          expect(file_set).to receive(:reload)
          expect(parent).not_to receive(:save)
          described_class.perform_now(file_set, file.id)
        end
      end

      context "when the parent was created more than a week ago" do
        let(:file_set) { create(:file_set) }

        it 'exports the file (for preservation)' do
          expect { described_class.perform_now(file_set, file.id) }
                              .to have_enqueued_job(BatchExport::ExportFileJob)
                                    .with(file_set)
        end
      end
    end
  end

  context "with a pdf file" do
    let(:file_set) { create(:file_set) }

    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, "issue_01_combined.pdf"))
        f.original_name = 'test.pdf'
        f.mime_type = 'application/pdf'
      end
    end

    before do
      file_set.original_file = file
      file_set.save!
    end

    it "runs a full text extract" do
      if system "vips -v"
        expect_any_instance_of(VipsDerivativesService).to receive(:create_vips_thumbnail)
      else
        expect(Hydra::Derivatives::PdfDerivatives).to receive(:create)
                                                        .with(/test\.pdf/, outputs: [{ label: :thumbnail,
                                                                                       format: 'jpg',
                                                                                       size: '338x493',
                                                                                       url: String,
                                                                                       layer: 0 }])
      end

      expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
                                                       .with(/test\.pdf/, outputs: [{ url: RDF::URI, container: "extracted_text" }])
      described_class.perform_now(file_set, file.id)
    end

    context 'with a parent object' do
      let(:parent) { create(:generic_work) }

      before do
        parent.ordered_members << file_set && parent.save
        file_set.reload
      end

      it 'resaves the parent and indexes the text' do
        described_class.perform_now(file_set, file.id)
        expect(SolrDocument.find(parent.id).full_text).to be_a(String)
      end

    end
  end
end
