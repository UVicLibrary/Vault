# frozen_string_literal: true
RSpec.describe Hyrax::DeepIndexingService do
  subject(:service) { described_class.new(work) }
  let(:work) { FactoryBot.build(:work) }

  before do
    newberg = <<RDFXML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
          <gn:Feature rdf:about="http://sws.geonames.org/5037649/">
          <rdfs:label>an RDFS Label</gn:name>
          <gn:name>Newberg</gn:name>
          </gn:Feature>
          </rdf:RDF>
RDFXML

    stub_request(:get, "http://sws.geonames.org/5037649/")
        .to_return(status: 200, body: newberg,
                   headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })
  end

  describe '#add_assertions' do
    it "adds the rdf_label from the authoritative source" do
      work.based_near_attributes = [{ id: 'http://sws.geonames.org/5037649/' }]

      expect { service.add_assertions(nil) }
          .to change { work.based_near.map(&:rdf_label).flatten }
                  .to contain_exactly(["Newberg"])
    end
  end

  describe '#append_label_and_uri' do
    context 'with genre field' do
      let(:field_info) { double('field_info') }
      let(:uri) { "http://vocab.getty.edu/aat/300020605" }
      let(:resource) { ActiveTriples::Resource.new(uri).fetch }
      let(:solr_doc) { {} }

      before do
        pompeii = <<RDFXML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8">
          <rdf:RDF
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <Subject xmlns="http://vocab.getty.edu/ontology#" rdf:about="http://vocab.getty.edu/aat/300020605">
            <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
            <rdf:type rdf:resource="http://vocab.getty.edu/ontology#Concept"/>
            <rdfs:label xml:lang="en">Pompeian wall painting styles</rdfs:label>
          </Subject>
          </rdf:RDF>
RDFXML

        stub_request(:get, uri)
            .to_return(status: 200, body: pompeii,
                       headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })
        allow(field_info).to receive(:behaviors).and_return([:stored_searchable])
      end

      it 'appends the English rdf label to the solr document' do
        service.append_to_solr_doc(solr_doc, "genre", field_info, resource)
        expect(solr_doc).to match({ "genre_tesim" => [uri],
                                    "genre_label_tesim" => ["Pompeian wall painting styles"] })
      end

      context 'with variant English spellings' do
        let(:uri) { "http://vocab.getty.edu/aat/300026096" }

        before do
          catalogs = <<RDFXML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8">
          <rdf:RDF
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <Subject xmlns="http://vocab.getty.edu/ontology#" rdf:about="http://vocab.getty.edu/aat/300026096">
            <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
            <rdf:type rdf:resource="http://vocab.getty.edu/ontology#Concept"/>
            <rdfs:label xml:lang="en-us">exhibition catalogs</rdfs:label>
            <rdfs:label xml:lang="en-gb">exhibition catalogues</rdfs:label>
          </Subject>
          </rdf:RDF>
RDFXML

          stub_request(:get, uri)
              .to_return(status: 200, body: catalogs,
                         headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })
          allow(field_info).to receive(:behaviors).and_return([:stored_searchable])
        end

        it 'append the English (US) rdf label to the solr document' do
          service.append_to_solr_doc(solr_doc, "genre", field_info, resource)
          expect(solr_doc).to match({ "genre_tesim" => [uri],
                                      "genre_label_tesim" => ["exhibition catalogs"] })
        end
      end
    end

  end

  describe '#solrize' do

    context 'with an ActiveTriples::Resource' do
      let(:value) { ActiveTriples::Resource.new('http://id.worldcat.org/fast/1333669') }
      before { value.fetch }

      it 'returns a tuple of URI and label' do
        expect(service.solrize(value)).to eq ['http://id.worldcat.org/fast/1333669',
                        { label: "Washington (State)--Mount Baker$http://id.worldcat.org/fast/1333669" }]
      end
    end

    context 'with a Hyrax::ControlledVocabularies::Field' do
      let(:value) { Hyrax::ControlledVocabularies::GeographicCoverage.new('http://id.worldcat.org/fast/1333669') }
      before { value.fetch }

      it 'returns a tuple of URI and label' do
        expect(service.solrize(value)).to eq ['http://id.worldcat.org/fast/1333669',
                          { label: "Washington (State)--Mount Baker$http://id.worldcat.org/fast/1333669" }]
      end

    end
  end
end