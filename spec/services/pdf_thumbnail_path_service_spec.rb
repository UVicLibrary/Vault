RSpec.describe PdfThumbnailPathService do

  let(:file_set) { FileSet.new(id: 'foo') }
  let(:object) { GenericWork.new(thumbnail_id: '999') }
  let(:collection) { Collection.new(title: ['Collection Title']) }
  subject { described_class.call(object) }

  before do
    allow(ActiveFedora::Base).to receive(:find).with('999').and_return(file_set)
    allow(file_set).to receive(:parent).and_return(object)
  end

  context "with a Work" do

    context 'not in any collection' do

      before do
        allow(object).to receive(:member_of_collections).and_return([])
      end

      context 'that has no thumbnail' do

        before do
          allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/pdf_thumbnails/misc/#{file_set.id}-thumb.jpg").and_return(false)
        end

        it { is_expected.to match %r{/(assets|images)\/work(.+)?\.png} }
      end

      context 'that has a thumbnail' do

        before do
          allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/pdf_thumbnails/misc/#{file_set.id}-thumb.jpg").and_return(true)
        end

        it { is_expected.to eq "/pdf_thumbnails/misc/foo-thumb.jpg" }
      end

    end

    context 'in a collection' do

      before do
        allow(object).to receive(:member_of_collections).and_return([collection])
      end

      context 'that has no thumbnail' do

        before do
          allow(File).to receive(:exist?).with(any_args)
          allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/pdf_thumbnails/collection_title/foo-thumb.jpg").and_return(false)
        end

        it { is_expected.to match %r{/(assets|images)\/work(.+)?\.png} }
      end

      context 'that has a thumbnail' do

        before do
          allow(File).to receive(:exist?).with("#{Rails.root.to_s}/public/pdf_thumbnails/collection_title/foo-thumb.jpg").and_return(true)
        end

        it { is_expected.to eq "/pdf_thumbnails/collection_title/foo-thumb.jpg" }
      end

    end

  end

end