RSpec.describe VaultThumbnailPathService do
  include Hyrax::FactoryHelpers

  subject { described_class.call(object) }

  context "with a FileSet" do
    let(:object) { build(:file_set, id: '999') }

    before do
      allow(object).to receive(:original_file).and_return(original_file)
      # https://github.com/samvera/active_fedora/issues/1251
      allow(object).to receive(:persisted?).and_return(true)
    end

    context "that has an image thumbnail" do
      let(:original_file) { mock_file_factory(mime_type: 'image/jpeg') }

      before { allow(File).to receive(:exist?).and_return(true) }
      it { is_expected.to eq IIIFWorkThumbnailPathService.call(object) }
    end

    context "that has no thumbnail" do
      let(:original_file) { mock_file_factory(mime_type: nil) }

      it { is_expected.to match %r{/assets/default-.+.png} }
    end
  end

  context "with a Work" do

    let(:object)         { GenericWork.new(thumbnail_id: '999') }
    let(:representative) { build(:file_set, id: '999') }

    before do
      allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
      allow(representative).to receive(:original_file).and_return(original_file)
    end

    context "that doesn't have a representative" do
      let(:object) { FileSet.new }
      let(:original_file)  { nil }

      it { is_expected.to match %r{/assets/default-.+.png} }
    end

    context "that has an image thumbnail" do
      let(:original_file)  { mock_file_factory(mime_type: 'image/jpeg') }

      before do
        allow(described_class).to receive(:thumbnail?).with(representative).and_return true
      end

      it { is_expected.to eq "/images/#{original_file.id}/full/!150,300/0/default.jpg" }

      context "and has more than one version" do

        let(:version) { ActiveFedora::VersionsGraph::ResourceVersion.new }

        before do
          allow(representative).to receive(:latest_content_version).and_return(version)
          version.label = "version2"
        end

        it "returns the path to the latest version" do
          expect(subject).to eq "/images/#{original_file.id}%2Ffcr:versions%2Fversion2/full/!150,300/0/default.jpg"
        end

      end
    end

    context "that has an audio thumbnail" do
      let(:original_file)  { mock_file_factory(mime_type: 'audio/mp3') }

      context "and is not in any collection" do
        it { is_expected.to match %r{audio(.+)?\.png} }
      end

      context "and is in a collection" do
        let(:collection) { Collection.new(id: "foo-bar") }

        before do
          allow(representative).to receive(:parent).and_return(object)
          allow(object).to receive(:member_of_collections).and_return([collection])
        end

        it { is_expected.to eq CollectionThumbnailPathService.call(collection) }
      end
    end

    context "that has an m4a thumbnail" do
      let(:representative) { build(:file_set, label: 'foo.m4a') }
      let(:original_file)  { mock_file_factory(mime_type: 'video/m4a') }

      it { is_expected.to match %r{audio(.+)?\.png} }
    end

    context "that has a pdf thumbnail" do
      let(:original_file)  { mock_file_factory(mime_type: 'application/pdf') }

      before do
        allow(described_class).to receive(:thumbnail?).with(representative).and_return true
      end

      it { is_expected.to eq(PdfThumbnailPathService.call(representative)) }
    end
  end



end
