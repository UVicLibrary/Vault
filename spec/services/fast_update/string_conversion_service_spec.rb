RSpec.describe FastUpdate::StringConversionService do
  subject { described_class.new("Tiffany and Company","http://id.worldcat.org/fast/549011") }
  let(:doc_needs_conversion) { {'id' => 'foo',
                                'creator_tesim' => ["Tiffany and Company", "Another string"],
                                'creator_label_tesim' => ["Tiffany and Company", "Another string"],
                                'provider_tesim' => ["http://id.worldcat.org/fast/549011"],
                                'provider_label_tesim' => ["Tiffany and Company"] } }

  describe '#call' do
    let(:work) { GenericWork.new(creator: ["Tiffany and Company", "A String"], title: ["A title"],
               provider: [Hyrax::ControlledVocabularies::Provider.new("http://id.worldcat.org/fast/549011")]) }

    before do
      allow(ActiveFedora::Base).to receive(:find).and_call_original # Need this for saving a work
      allow(ActiveFedora::Base).to receive(:find).with("foo").and_return(work)
    end

    it 'replaces strings with uris and saves the object' do
      subject.call(doc_needs_conversion)
      # Each value should be an instance of Hyrax::ControlledVocabularies::Creator or a String
      expect(work.creator.map(&:class)).to all(be_in([Hyrax::ControlledVocabularies::Creator, String]))
      expect(work.creator).to match_array([Hyrax::ControlledVocabularies::Creator.new("http://id.worldcat.org/fast/549011"),
                                           "A String"])
    end
  end

  describe '#search_for_new_headings' do
    let(:document2) { {'creator_tesim' => "http://id.worldcat.org/fast/1432983",
                       'creator_label_tesim' => "Tiffany Studios (New York, N.Y.)" } }
    let(:response) { { 'response' => { 'docs' => [doc_needs_conversion, document2] } } }

    it 'searches for documents that need to be converted' do
      allow(ActiveFedora::SolrService).to receive(:get).with(any_args).and_return(response)
      expect(ActiveFedora::SolrService).to receive(:get).with(subject.send(:label_query), { rows: 12000, sort: "has_model_ssim desc" } )
      expect(subject.search_for_new_headings).to eq([doc_needs_conversion])
    end
  end

  describe 'document methods' do

    describe '#needs_conversion?' do
      let(:doc_already_converted) { {'creator_tesim' => "http://id.worldcat.org/fast/549011",
                                     'creator_label_tesim' => "Tiffany and Company" } }

      it 'returns true when field contains a string' do
        expect(subject.send(:needs_conversion?, doc_needs_conversion, :creator)).to be true
      end

      it 'returns false when field contains a uri' do
        expect(subject.send(:needs_conversion?, doc_already_converted, :creator)).to be false
      end
    end

    describe '#fields_for_conversion?' do
      it 'returns the fields that need converting' do
        expect(subject.send(:fields_for_conversion, doc_needs_conversion)).to include(:creator)
        expect(subject.send(:fields_for_conversion, doc_needs_conversion)).not_to include(:provider)
      end
    end
  end


  describe '#convert_to_uris' do
    let(:work) { GenericWork.new(contributor: ["Tiffany and Company",
                 Hyrax::ControlledVocabularies::Contributor.new("http://id.worldcat.org/fast/1432983")]) }

    it 'converts strings to uris' do
      subject.send(:convert_to_uris, work, :contributor)
      expect(work.contributor).to all(be_instance_of(Hyrax::ControlledVocabularies::Contributor))
      expect(work.contributor.map(&:id)).to match_array(["http://id.worldcat.org/fast/549011",
                                                         "http://id.worldcat.org/fast/1432983"])
    end
  end

end