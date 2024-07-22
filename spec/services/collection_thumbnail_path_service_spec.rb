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

      context 'with an image thumbnail' do
        before do
          allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(file).and_return("#{file.id}/fcr:versions/version2")
        end

        it "uses the latest version" do
          expect(subject).to eq "/images/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470%2Ffcr:versions%2Fversion2/full/!500,900/0/default.jpg"
        end
      end

      context 'with a video thumbnail' do
        subject { described_class.call(collection) }

        before do
          allow(described_class).to receive(:video?).with(file_set).and_return(true)
          allow(Hyrax::VersioningService).to receive(:versioned_file_id).with(file).and_return(file.id)
        end

        context 'with no generated image file' do
          it { is_expected.to start_with '/assets/collection-' }
        end

        context 'with a generated image file' do
          let(:path) { Hyrax::DerivativePath.derivative_path_for_reference(file_set, 'thumbnail') }
          before { allow(File).to receive(:exist?).with(path).and_return(true) }

          it { is_expected.to eq "/downloads/s1784k724?file=thumbnail" }
        end
      end

      context 'with a pdf thumbnail' do

        before { allow(file_set).to receive(:pdf?).and_return true }

        it { is_expected.to eq("/pdf_thumbnails/s1784k724-thumb.jpg") }
      end

    end

    context "using a Hyrax::FileSet" do
      before { allow(Hyrax.config).to receive(:use_valkyrie?).and_return true }

      context "with an image thumbnail" do
        let(:file_set) { FactoryBot.create(:file_set, :with_original_file) }

        before do
          allow(ActiveFedora::Base).to receive(:find).and_call_original
          allow(file_set).to receive(:original_file).and_call_original
        end

        it "includes the version in the URL" do
          expect(subject).to eq "/images/#{CGI.escape("#{file_set.original_file.id}/fcr:versions/version1").gsub("%3A",":")}/full/!500,900/0/default.jpg"
        end
      end

      context "with a video thumbnail" do
        let(:file) { double(id: '1001') }
        let(:file_metadata) { FactoryBot.build(:hyrax_file_metadata, mime_type: 'video/mp4') }

        before do
          allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:video?).and_return true
          allow(File).to receive(:exist?).with(Hyrax::DerivativePath.derivative_path_for_reference(file_set, 'thumbnail')).and_return true
          allow(file_metadata).to receive(:original_filename).and_return('video.mp4')
          allow(Hyrax.custom_queries).to receive(:find_file_metadata_by)
                                             .with(id: Valkyrie::ID.new('1001'))
                                             .and_return(file_metadata)
        end

        it { is_expected.to eq("/downloads/s1784k724?file=thumbnail") }
      end

      context "with a pdf thumbnail" do
        let(:file) { double(id: '1001') }
        let(:file_metadata) { FactoryBot.build(:hyrax_file_metadata, mime_type: 'application/pdf') }

        before do
          allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:pdf?).and_return true
          allow(file_metadata).to receive(:original_filename).and_return('video.mp4')
          allow(Hyrax.custom_queries).to receive(:find_file_metadata_by)
                                             .with(id: Valkyrie::ID.new('1001'))
                                             .and_return(file_metadata)
        end

        it { is_expected.to eq("/pdf_thumbnails/s1784k724-thumb.jpg") }
      end

    end

    context "without a thumbnail" do
      before { allow(collection).to receive(:thumbnail_id).and_return nil }

      it { is_expected.to start_with '/assets/collection-' }
    end
  end

end
