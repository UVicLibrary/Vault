RSpec.describe FastUpdate::UriConversionService do
  subject { described_class.new("http://id.worldcat.org/fast/549011", ["http://id.worldcat.org/fast/1432983"]) }
  let(:collection) { build(:collection_lw, id: "foo") }
  let(:collection_service) { described_class.new("http://id.worldcat.org/fast/549011",
                                                 ["http://id.worldcat.org/fast/1432983"],
                                                                 collection) }
  let(:document) { { 'id' => 'foo',
                     'creator_tesim' => ["http://id.worldcat.org/fast/549011", "A String"],
                     'provider_tesim' => "http://id.worldcat.org/fast/1432983" } }

  describe '#call' do
    let(:work) { GenericWork.new(creator: [Hyrax::ControlledVocabularies::Creator.new("http://id.worldcat.org/fast/549011"),"A String"],
                                 title: ["A title"],
                                 provider: [Hyrax::ControlledVocabularies::Provider.new("http://id.worldcat.org/fast/549011")]) }

    before do
      allow(ActiveFedora::Base).to receive(:find).and_call_original # Need this for saving a work
      allow(ActiveFedora::Base).to receive(:find).with("foo").and_return(work)
    end

    context 'when replacing with one uri' do
      it 'replaces one uri with another and saves the object' do
        subject.call(document)
        # Each value should be an instance of Hyrax::ControlledVocabularies::Creator or a String
        expect(work.creator.map(&:class)).to all(be_in([Hyrax::ControlledVocabularies::Creator, String]))
        expect(work.creator).to match_array([Hyrax::ControlledVocabularies::Creator.new("http://id.worldcat.org/fast/1432983"),
                                             "A String"])
      end
    end

    context 'when replacing with multiple uris' do
      subject { described_class.new("http://id.worldcat.org/fast/549011",
                                    ["http://id.worldcat.org/fast/1432983","http://id.worldcat.org/fast/1746676"]) }
      it 'replaces one uri with multiple uris and saves the object' do
        subject.call(document)
        # Each value should be an instance of Hyrax::ControlledVocabularies::Creator or a String
        expect(work.creator.map(&:class)).to all(be_in([Hyrax::ControlledVocabularies::Creator, String]))
        expect(work.creator).to match_array([Hyrax::ControlledVocabularies::Creator.new("http://id.worldcat.org/fast/1432983"),
                                             Hyrax::ControlledVocabularies::Creator.new("http://id.worldcat.org/fast/1746676"),
                                             "A String"])
      end
    end
  end

  describe '#search_for_uri' do
    let(:stub_result) { {"response" => { "docs" => [document] } } }

    before { allow(ActiveFedora::SolrService).to receive(:get).with(any_args).and_return(stub_result) }

    context 'when no collection is specified' do
      it 'searches the whole repository' do
        expect(ActiveFedora::SolrService).to receive(:get).with(subject.send(:uri_query), { rows: 12000 } )
        expect(subject.search_for_uri).to eq([document])
      end
    end

    context 'when limited to a single collection' do
      let(:query_service) { Hyrax::SolrQueryService.new }
      let(:fs_doc) { { 'creator_tesim' => "http://id.worldcat.org/fast/549011" } }
      let(:fs_doc2) { { "no_changes_needed" => "foo" } }
      let(:fs_response) { { "response" => { "docs" => [fs_doc] } } }

      before do
        allow(Hyrax::SolrQueryService).to receive(:new).and_return(query_service)
        # Give it a "file set" to search for
        document['member_ids_ssim'] = ["foobar"]
        # Stub the response when looking for file sets
        allow(query_service).to receive(:get).and_return(fs_response)
      end

      it 'finds works and file sets in that collection with the old uri' do
        expect(collection_service.search_for_uri).to eq([document, fs_doc])
      end
    end
  end

  describe '#needs_conversion?' do
    context 'when a document has the old uri' do
      it 'returns true' do
        expect(subject.send(:needs_conversion?, document, :creator)).to be true
      end
    end

    context "when a document doesn't have the old uri" do
      let(:document2) { { 'id' => 'foo', 'creator_tesim' => "http://id.worldcat.org/fast/1432983" }}
      it 'returns false' do
        expect(subject.send(:needs_conversion?, document2, :creator)).to be false
      end
    end
  end

  describe '#fields_for_conversion' do
    it 'returns fields that contain the old uri' do
      expect(subject.send(:fields_for_conversion, document)).to include(:creator)
      expect(subject.send(:fields_for_conversion, document)).not_to include(:provider)
    end
  end

  describe '#uri_query' do
    let(:expected_query) { ["(_query_:\"{!field f=based_near_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=creator_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=contributor_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=physical_repository_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=provider_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=subject_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=geographic_coverage_tesim}http://id.worldcat.org/fast/549011\"",
                            "_query_:\"{!field f=genre_tesim}http://id.worldcat.org/fast/549011\")"].join(" OR ") }

    it 'returns a joined query to search the full repository' do
      expect(subject.send(:uri_query)).to eq expected_query
    end

    context 'when limited to a collection' do
      it 'returns a joined query limited to members of a collection' do
        expect(collection_service.send(:uri_query)).to eq "#{expected_query} AND _query_:\"{!field f=member_of_collection_ids_ssim}foo\""
      end
    end
  end

  describe '#collection_query' do
    it 'returns a query limited to members of a collection' do
      expect(collection_service.send(:collection_query)).to eq("_query_:\"{!field f=member_of_collection_ids_ssim}foo\"")
    end
  end
end