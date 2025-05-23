# frozen_string_literal: true
require File.join("#{Rails.root}","app","models","ability.rb")

RSpec.describe GenericWorkIndexer do
  subject(:solr_document) { service.generate_solr_document }

  # TODO: file_set_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let(:service) { described_class.new(work) }
  let(:work) { build(:generic_work, creator: ["http://id.worldcat.org/fast/549011"],
                      geographic_coverage: ["http://id.worldcat.org/fast/1243522"],
                      chronological_coverage: ["1943/1945"],
                      date_created: date_created,
                      resource_type:["http://purl.org/dc/dcmitype/StillImage"]) }
  let(:date_created) {["1943/1945"] }

  it 'uses VaultThumbnailPathService to index thumbnail paths' do
    expect(described_class.thumbnail_path_service).to eq VaultThumbnailPathService
  end

  it 'indexes a title field for sorting alphabetically' do
    expect(solr_document['title_sort_ssi']).to eq 'Test title'
  end

  it 'indexes other metadata fields' do
    expect(solr_document['creator_tesim']).to eq ["http://id.worldcat.org/fast/549011"]
    expect(solr_document['geographic_coverage_tesim']).to eq ["http://id.worldcat.org/fast/1243522"]
    expect(solr_document['chronological_coverage_tesim']).to eq ["1943/1945"]
    expect(solr_document['date_created_tesim']).to eq ["1943/1945"]
    expect(solr_document['resource_type_tesim']).to eq ["http://purl.org/dc/dcmitype/StillImage"]
  end

  it 'indexes OAI-PMH fields' do
    expect(solr_document['oai_dc_coverage_tesim']).to eq(['United States--Pacific Coast','1943/1945'])
    expect(solr_document['oai_dc_type_tesim']).to eq(["StillImage"])
    expect(solr_document['oai_dc_relation_tesim']).to eq([])
  end

  describe 'date indexing' do
    context 'with a single date_created value' do
      it 'indexes extra (EDTF) datetime fields for sorting and blacklight_range_limit' do
        expect(solr_document['year_range_isim']).to eq([1943, 1944, 1945])
        expect(solr_document['year_sort_dtsi']).to eq "1943-01-01T00:00:00Z"
      end
    end

    context 'with multiple date_created values' do
      let(:date_created) { ["1940-01-09", "1943/1945"] }

      it 'indexes the correct EDTF datetime fields' do
        expect(solr_document['year_range_isim']).to eq([1940, 1943, 1944, 1945])
        expect(solr_document['year_sort_dtsi']).to eq "1940-01-09T00:00:00Z"
      end
    end

    context 'with unknown' do
      let(:date_created) { ["unknown"] }

      it "does not index anything in year_range_isim or year_sort_dtsi" do
        expect(solr_document['year_range_isim']).to be_nil
        expect(solr_document['year_sort_dtsi']).to be_nil
      end
    end
  end

  context 'without explicit visibility set' do
    it 'indexes visibility' do
      expect(solr_document['visibility_ssi']).to eq 'restricted' # tight default
    end
  end

  context 'with authenticated visibility set' do
    before { allow(work).to receive(:visibility).and_return('authenticated') }

    it 'indexes visibility' do
      expect(solr_document['visibility_ssi']).to eq 'authenticated'
    end

    it 'allows public users to discover the work' do
      expect(solr_document['discover_access_group_ssim']).to eq ['public']
    end
  end

  context 'with public work that is downloadable' do
    let(:permissions) {
      [ Hydra::AccessControls::Permission.new(name: "public",
                                              type: "group",
                                              access: "download")]
    }

    before do
      allow(work).to receive(:visibility).and_return('open')
      allow(work).to receive(:permissions).and_return(permissions)
    end

    it 'indexes "public" in download groups' do
      expect(solr_document['download_access_group_ssim']).to eq ['public']
    end
  end

  context 'with specified download permissions' do
    let(:permissions) do
      [ Hydra::AccessControls::Permission.new(name: "group1",
                                               type: "group",
                                               access: "download"),
      Hydra::AccessControls::Permission.new(name: "user1",
                                             type: "person",
                                             access: "download")]
    end
    before { allow(work).to receive(:permissions).and_return(permissions) }

    it 'indexes download permissions' do
      expect(solr_document['download_access_group_ssim']).to eq ['group1']
      expect(solr_document['download_access_user_ssim']).to eq ['user1']
    end
  end

  context "with child works" do
    let!(:work) { create(:work_with_one_file, user: user) }
    let!(:child_work) { create(:generic_work, user: user) }
    let(:file) { work.file_sets.first }

    before do
      work.works << child_work
      allow(VaultThumbnailPathService).to receive(:call).and_return("/images/#{file.id}/full/!150,300/0/default.jpg")
      work.representative_id = file.id
      work.thumbnail_id = file.id
    end

    it 'indexes member work and file_set ids' do
      expect(solr_document['member_ids_ssim']).to eq work.member_ids
      expect(solr_document['generic_type_sim']).to eq ['Work']
      expect(solr_document.fetch('thumbnail_path_ss')).to eq "/images/#{file.id}/full/!150,300/0/default.jpg"
      expect(subject.fetch('hasRelatedImage_ssim').first).to eq file.id
      expect(subject.fetch('hasRelatedMediaFragment_ssim').first).to eq file.id
    end

    context "when thumbnail_field is configured" do
      before do
        service.thumbnail_field = 'thumbnail_url_ss'
      end
      it "uses the configured field" do
        expect(solr_document.fetch('thumbnail_url_ss')).to eq "/images/#{file.id}/full/!150,300/0/default.jpg"
      end
    end

    context "when a full text transcript is available" do

      let(:file_set) { FileSet.new }
      let(:txtfile1) { Hydra::PCDM::File.new(uri: "foo") }
      let(:txtfile2) { Hydra::PCDM::File.new(uri: "foobar") }

      before do
        allow(file).to receive(:extracted_text).and_return(txtfile1)
        allow(file_set).to receive(:extracted_text).and_return(txtfile2)
        allow(txtfile1).to receive(:present?).and_return(true)
        allow(txtfile2).to receive(:present?).and_return(true)
        allow(txtfile1).to receive(:content).and_return("Some text.")
        allow(txtfile2).to receive(:content).and_return(" Other text.")
        allow(work).to receive(:file_sets).and_return([file, file_set])
      end

      it "indexes the transcript in full_text_tsi" do
        expect(solr_document['full_text_tsi']).to eq "Some text. Other text."
      end
    end
  end

  context "with an AdminSet" do
    let(:work) { create(:generic_work, admin_set: admin_set) }
    let(:admin_set) { create(:admin_set, title: ['Title One']) }

    it "indexes the correct fields" do
      expect(solr_document.fetch('admin_set_sim')).to eq ["Title One"]
      expect(solr_document.fetch('admin_set_tesim')).to eq ["Title One"]
    end
  end

  context "the object status" do
    before { allow(work).to receive(:suppressed?).and_return(suppressed) }
    context "when suppressed" do
      let(:suppressed) { true }

      it "indexes the suppressed field with a true value" do
        expect(solr_document.fetch('suppressed_bsi')).to be true
      end
    end

    context "when not suppressed" do
      let(:suppressed) { false }

      it "indexes the suppressed field with a false value" do
        expect(solr_document.fetch('suppressed_bsi')).to be false
      end
    end
  end

  context "the actionable workflow roles" do
    let(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    before do
      work.save
      allow(Sipity).to receive(:Entity).with(work).and_return(sipity_entity)
      allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_roles_associated_with_the_given_entity)
        .and_return(['approve', 'reject'])
    end

    it "indexed the roles and state" do
      expect(solr_document.fetch('actionable_workflow_roles_ssim')).to eq [
        "#{sipity_entity.workflow.permission_template.source_id}-#{sipity_entity.workflow.name}-approve",
        "#{sipity_entity.workflow.permission_template.source_id}-#{sipity_entity.workflow.name}-reject"
      ]
      expect(solr_document.fetch('workflow_state_name_ssim')).to eq "initial"
    end
  end

  describe "with a remote resource (based near)" do
    # You can get the original RDF+XML here:
    # https://sws.geonames.org/5037649/about.rdf Note: in this RDF+XML
    # document, the only "English readable" identifying attributes are
    # the nodes: `gn:name` and `gn:countryCode`.  In other words the
    # helpful administrative container (e.g. Minnesota) is not in this
    # document.
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
      work.based_near_attributes = [{ id: 'http://sws.geonames.org/5037649/' }]
      work.save

      stub_request(:get, "http://sws.geonames.org/5037649/")
        .to_return(status: 200, body: mpls,
                   headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })

      stub_request(:get, 'http://www.geonames.org/getJSON')
        .with(query: hash_including({ 'geonameId': '5037649' }))
        .to_return(status: 200, body: File.open(File.join(fixture_path, 'geonames.json')))
    end

    it "indexes id and label" do
      expect(solr_document.fetch('based_near_sim')).to eq ["http://sws.geonames.org/5037649/"]
      expect(solr_document.fetch('based_near_label_sim')).to eq ["Minneapolis, Minnesota, United States"]
    end

    describe '#to_controlled_vocab' do
      it "converts the object's controlled properties" do
        expect(work.creator.first).to be_instance_of(Hyrax::ControlledVocabularies::Creator)
        expect(work.creator.first.id).to eq "http://id.worldcat.org/fast/549011"
      end
    end

    describe 'with nested parent collections' do
      let(:parent) { create(:collection_lw, title: ["Parent collection"]) }
      let(:child) { build(:collection_lw, title: ["Subcollection"] ) }

      before do
        child.member_of_collections = [parent]
        child.save
        work.member_of_collections = [child]
        work.save
      end

      it 'indexes (nested) parent collection titles' do
        expect(solr_document.fetch('nested_member_of_collections_ssim')).to eq ["Parent collection", "Subcollection"]
      end

    end

  end
end
