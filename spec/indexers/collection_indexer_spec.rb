RSpec.describe CollectionIndexer do
  subject(:solr_document) { service.generate_solr_document }

  let(:user) { create(:user) }
  let(:service) { described_class.new(collection) }
  let(:collection) { build(:collection_lw, creator: ["http://id.worldcat.org/fast/549011"],
                           geographic_coverage: ["http://id.worldcat.org/fast/1243522"],
                           resource_type:["http://purl.org/dc/dcmitype/StillImage"],
                           based_near: ["http://sws.geonames.org/6174041/","http://sws.geonames.org/1814991"]) }

  it 'indexes a title field for sorting alphabetically' do
    expect(solr_document['title_sort_ssi']).to eq collection.title.first
  end

  it 'indexes OAI-PMH fields' do
    expect(solr_document['oai_dc_coverage_tesim']).to eq(['United States--Pacific Coast'])
    expect(solr_document['oai_dc_type_tesim']).to eq(["StillImage"])
    expect(solr_document['oai_dc_relation_tesim']).to eq([])
  end

  it 'indexes the geonames hierarchy in a location sort field' do
    expect(solr_document['location_sort_tesim']).to match_array(
            ["Victoria","Vancouver Island", "British Columbia", "North America", "Canada", "China","Asia"])
  end

  context 'with a thumbnail' do
    before do
      allow(CollectionThumbnailPathService).to receive(:call).with(collection).and_return("/images/foo%2Ffiles%2Ffoo2/full/!500,900/0/default.jpg")
    end

    it 'indexes the thumbnail path' do
      expect(solr_document['thumbnail_path_ss']).to eq "/images/foo%2Ffiles%2Ffoo2/full/!500,900/0/default.jpg"
    end
  end

  context 'without explicit visibility set' do
    it 'indexes visibility' do
      expect(solr_document['visibility_ssi']).to eq 'restricted' # tight default
    end
  end

  context 'with authenticated visibility set' do
    before { allow(collection).to receive(:visibility).and_return('authenticated') }

    it 'indexes visibility' do
      expect(solr_document['visibility_ssi']).to eq 'authenticated'
    end

    it 'allows public users to discover the collection' do
      expect(solr_document['discover_access_group_ssim']).to eq ['public']
    end
  end

  context "with subcollections or parent collections" do
    let(:parent_collection) { build(:collection_lw, id: "foo") }
    before { allow(collection).to receive(:in_collections).and_return([parent_collection]) }
    before { allow(collection).to receive(:member_of_collections).and_return([parent_collection]) }

    it 'indexes parent collection id in member_of_collection_ids_ssim' do
      expect(solr_document['member_of_collection_ids_ssim']).to eq [parent_collection.id]
    end
  end

  describe "with a remote resource (based near)" do
    mpls = <<RDFXML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
          <gn:Feature rdf:about="http://sws.geonames.org/5037649/">
          <gn:name>Minneapolis</gn:name>
          </gn:Feature>
          </rdf:RDF>
RDFXML

    before do
      allow(service).to receive(:rdf_service).and_return(Hyrax::DeepIndexingService)
      collection.based_near = ['http://sws.geonames.org/5037649/']
      stub_request(:get, "http://sws.geonames.org/5037649/")
        .to_return(status: 200, body: mpls,
                   headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })
    end

    it "indexes id and label" do
      expect(solr_document.fetch('based_near_sim')).to eq ["http://sws.geonames.org/5037649/"]
      expect(solr_document.fetch('based_near_label_sim')).to eq ["Minneapolis, Minnesota, United States"]
    end
  end

  describe '#to_controlled_vocab' do
    it "converts the object's controlled properties" do
      subject
      expect(collection.creator.first).to be_instance_of(Hyrax::ControlledVocabularies::Creator)
      expect(collection.creator.first.id).to eq "http://id.worldcat.org/fast/549011"
    end
  end

  describe 'with nested parent collections' do
    let(:parent) { create(:collection_lw, title: ["Parent collection"]) }
    let(:child) { build(:collection_lw, title: ["Subcollection"] ) }

    before do
      child.member_of_collections = [parent]
      child.save
      collection.member_of_collections = [child]
      collection.save
    end

    it 'indexes (nested) parent collection titles' do
      expect(solr_document.fetch('nested_member_of_collections_ssim')).to eq ["Parent collection", "Subcollection"]
    end

  end
end
