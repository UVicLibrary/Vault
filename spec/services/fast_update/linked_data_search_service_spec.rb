RSpec.describe FastUpdate::LinkedDataSearchService do
  subject { described_class.new("Tiffany and Company","http://id.worldcat.org/fast/549011") }

  describe '#label_query' do
    it 'returns a joined query for searching label fields' do
      query = ["(_query_:\"{!field f=based_near_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=creator_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=contributor_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=physical_repository_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=provider_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=subject_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=geographic_coverage_label_tesim}Tiffany and Company\"",
               "_query_:\"{!field f=genre_label_tesim}Tiffany and Company\")"].join(" OR ")
      expect(subject.send(:label_query)).to eq query
    end
  end

  describe '#uri_query' do
    it 'returns a joined query for searching controlled property fields' do
      query = ["(_query_:\"{!field f=based_near_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=creator_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=contributor_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=physical_repository_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=provider_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=subject_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=geographic_coverage_tesim}http://id.worldcat.org/fast/549011\"",
               "_query_:\"{!field f=genre_tesim}http://id.worldcat.org/fast/549011\")"].join(" OR ")
      expect(subject.send(:uri_query)).to eq query
    end
  end

  describe 'search methods' do

    describe '#search_for_label' do
      it 'searches Solr for documents with the label in label fields' do
        stub_result = { "response" => { "docs" => "Foo" } }
        allow(ActiveFedora::SolrService).to receive(:get).with(any_args).and_return(stub_result)
        expect(ActiveFedora::SolrService).to receive(:get).with(subject.send(:label_query), { rows: 12000, sort: "has_model_ssim desc" } )
        expect(subject.search_for_label).to eq("Foo")
      end
    end

    describe '#search_for_uri' do
      it 'searches Solr for documents with the uri in controlled property fields' do
        stub_result = { "response" => { "docs" => "Foo" } }
        allow(ActiveFedora::SolrService).to receive(:get).with(any_args).and_return(stub_result)
        expect(ActiveFedora::SolrService).to receive(:get).with(subject.send(:uri_query), { rows: 12000, sort: "has_model_ssim desc" } )
        expect(subject.search_for_uri).to eq("Foo")
      end
    end

    describe '#search_for_modified_headings' do
      before { allow(subject).to receive(:search_for_uri).and_return([document]) }

      context 'when document has the old label' do
        let(:document) { {'creator_tesim' => "http://id.worldcat.org/fast/549011",
                          'creator_label_tesim' => "old label" } }

        it 'returns the document' do
          expect(subject.search_for_modified_headings).to eq([document])
        end
      end

      context 'when document has the most recent label' do
        let(:document) { {'creator_tesim' => "http://id.worldcat.org/fast/549011",
                          'creator_label_tesim' => "Tiffany and Company" } }

        it 'returns an empty array' do
          expect(subject.search_for_modified_headings).to eq([])
        end
      end
    end
  end

  describe '#has_old_label?' do
    let(:doc_with_old_label) { {'creator_tesim' => "http://id.worldcat.org/fast/549011",
                                'creator_label_tesim' => "old label" } }
    let(:doc_with_new_label) {  {'creator_tesim' => "http://id.worldcat.org/fast/549011",
                                 'creator_label_tesim' => "Tiffany and Company" } }

    context 'when document has the old label' do
      it 'returns true' do
        expect(subject.send(:has_old_label?, doc_with_old_label, :creator)).to be true
      end
    end

    context 'when document has the most recent label' do
      it 'returns false' do
        expect(subject.send(:has_old_label?, doc_with_new_label, :creator)).to be false
      end
    end
  end
end