RSpec.describe CollectionThumbnailPathService do

  let(:file_set) { FileSet.new(id: 's1784k724') }
  let(:file) do
    double(id: 's1/78/4k/72/s1784k724/files/6185235a-79b2-4c29-8c24-4d6ad9b11470',
           mime_type: 'image/jpeg')
  end
  subject { described_class.call(collection) }
  let(:collection) { build(:collection, thumbnail_id: file_set.id, id: 'foo') }

  before do
    # Stubbing this lets byebug work
    allow(File).to receive(:exist?).with(any_args).and_call_original
    allow(ActiveFedora::Base).to receive(:find).with(file_set.id).and_return(file_set)
    allow(collection).to receive(:thumbnail_id).and_return(file_set.id)
    allow(file_set).to receive_messages(original_file: file, id: 's1784k724')
    # https://github.com/projecthydra/active_fedora/issues/1251
    allow(file_set).to receive(:persisted?).and_return(true)
  end

  context "on a collection" do

    context "with an uploaded thumbnail" do
      before do
        allow(File).to receive(:exist?)
                       .with("#{Rails.root.to_s}/public/uploads/uploaded_collection_thumbnails/foo/foo_card.jpg")
                       .and_return(true)
      end

      it { is_expected.to eq "/uploads/uploaded_collection_thumbnails/foo/foo_card.jpg" }
    end

    context "with a thumbnail selected from an ActiveFedora work/file set" do

      before { allow(ActiveFedora::Base).to receive(:find).with(file_set.id).and_return(file_set) }


    end

    context "using a Hyrax::FileSet" do
      before { allow(Hyrax.config).to receive(:use_valkyrie?).and_return true }

      context "with a thumbnail" do
        let(:file_metadata) { FactoryBot.build(:hyrax_file_metadata) }

        before do
          allow(Hyrax.custom_queries).to receive(:find_file_metadata_by).and_return(file_metadata)
          allow(file_metadata).to receive(:original_filename).and_return 'smthg.mp4'
          allow(Hyrax.custom_queries).to receive(:find_thumbnail).and_return true
        end

        it { is_expected.to eq("/downloads/s1784k724?file=thumbnail") }
      end

    end

    context "using an ActiveFedora file set" do
      before { allow(Hyrax.config).to receive(:use_valkyrie?).and_return false }

      context "with a thumbnail" do
        let(:file_metadata) { FactoryBot.build(:hyrax_file_metadata) }

        before do
          allow(Hyrax.custom_queries).to receive(:find_file_metadata_by).and_return(file_metadata)
          allow(file_metadata).to receive(:original_filename).and_return 'smthg.mp4'
          allow(File).to receive(:exist?).with(Hyrax::DerivativePath.derivative_path_for_reference(file_set, 'thumbnail')).and_return true
        end

        it { is_expected.to eq("/downloads/s1784k724?file=thumbnail") }
      end

    end

    context "without a thumbnail" do
      before { allow(collection).to receive(:thumbnail_id).and_return nil }

      it { is_expected.to start_with '/assets/collection-' }
    end
  end

end
