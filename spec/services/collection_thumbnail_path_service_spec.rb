RSpec.describe CollectionThumbnailPathService do
  let(:file_set) { FileSet.new }
  let(:file) do
    double(id: 's1/78/4k/72/s1784k724/files/6185235a-79b2-4c29-8c24-4d6ad9b11470',
           mime_type: 'image/jpeg')
  end

  before do
    # Lets byebug work
    allow(File).to receive(:exist?).with(any_args).and_call_original
    allow(FileSet).to receive(:find).with('s1784k724').and_return(file_set)
    allow(file_set).to receive_messages(original_file: file, id: 's1784k724')
    # https://github.com/projecthydra/active_fedora/issues/1251
    allow(file_set).to receive(:persisted?).and_return(true)
  end

  context "on a collection" do
    subject { described_class.call(collection) }
    let(:collection) { build(:collection, thumbnail_id: 's1784k724', id: 'foo') }

    context "with an uploaded thumbnail" do
      before do
        allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg").and_return(true)
      end

      it { is_expected.to eq "/uploaded_collection_thumbnails/foo/foo_card.jpg" }
    end

    context "with a thumbnail selected from a work/file set" do

      before do
        allow(collection).to receive(:thumbnail).and_return(file_set)
        allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg").and_return(false)
        allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(file).and_return(file.id)
      end

      it { is_expected.to eq '/images/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/!500,900/0/default.jpg' }

      context "that has multiple versions" do

        before do
          allow(collection).to receive(:thumbnail).and_return(file_set)
          allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg").and_return(false)
          allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(file).and_return("#{file.id}/fcr:versions/version2")
        end

        it "uses the latest version" do
          expect(subject).to eq "/images/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470%2Ffcr:versions%2Fversion2/full/!500,900/0/default.jpg"
        end
      end
    end

    context "without a thumbnail" do
      let(:collection) { build(:collection) }

      it { is_expected.to start_with '/assets/collection-' }
    end
  end

end
