# frozen_string_literal: true
RSpec.describe ::SolrDocument, type: :model do
  subject(:document) { described_class.new(attributes) }
  let(:attributes) { {} }

  describe "#itemtype" do
    let(:attributes) { { resource_type_tesim: ['Article'] } }

    its(:itemtype) { is_expected.to eq 'http://schema.org/Article' }

    it "delegates to the Hyrax::ResourceTypesService" do
      expect(Hyrax::ResourceTypesService).to receive(:microdata_type).with('Article')
      document.itemtype
    end

    context 'with no resource_type' do
      let(:attributes) { {} }

      its(:itemtype) { is_expected.to eq 'http://schema.org/CreativeWork' }
    end
  end

  describe "date_uploaded" do
    let(:attributes) { { 'date_uploaded_dtsi' => '2013-03-14T00:00:00Z' } }

    its(:date_uploaded) { is_expected.to eq Date.parse('2013-03-14') }

    context "when an invalid type is provided" do
      let(:attributes) { { 'date_uploaded_dtsi' => 'Test' } }

      it "logs parse errors" do
        expect(Hyrax.logger).to receive(:info).with(/Unable to parse date.*/)
        document.date_uploaded
      end
    end
  end

  describe "rights_statement" do
    let(:attributes) { { 'rights_statement_tesim' => ['A rights statement'] } }

    it "responds to rights_statement" do
      expect(document).to respond_to(:rights_statement)
    end

    it "returns the proper data" do
      expect(document.rights_statement).to eq ['A rights statement']
    end
  end

  describe "create_date" do
    let(:attributes) { { 'system_create_dtsi' => '2013-03-14T00:00:00Z' } }

    its(:create_date) { is_expected.to eq Date.parse('2013-03-14') }

    context "when an invalid type is provided" do
      let(:attributes) { { 'system_create_dtsi' => 'Test' } }

      it "logs parse errors" do
        expect(Hyrax.logger).to receive(:info).with(/Unable to parse date.*/)
        document.create_date
      end
    end
  end

  describe "resource_type" do
    let(:attributes) { { 'resource_type_tesim' => ['Image'] } }

    its(:resource_type) { is_expected.to eq ['Image'] }
  end

  describe "thumbnail_path" do
    let(:attributes) { { 'thumbnail_path_ss' => ['/foo/bar'] } }

    its(:thumbnail_path) { is_expected.to eq '/foo/bar' }
  end

  describe '#to_param' do
    let(:id) { '1v53kn56d' }
    let(:attributes) { { id: id } }

    its(:to_param) { is_expected.to eq id }
  end

  describe "#suppressed?" do
    let(:attributes) { { 'suppressed_bsi' => suppressed_value } }

    context 'when true' do
      let(:suppressed_value) { true }

      it { is_expected.to be_suppressed }
    end

    context 'when false' do
      let(:suppressed_value) { false }

      it { is_expected.not_to be_suppressed }
    end
  end
  describe "document types" do
    class Mimes
      include Hydra::Works::MimeTypes
    end

    Mimes.office_document_mime_types.each do |type|
      context "when mime-type is #{type}" do
        let(:attributes) { { 'mime_type_ssi' => type } }

        it { is_expected.to be_office_document }
      end
    end

    Mimes.video_mime_types.each do |type|
      context "when mime-type is #{type}" do
        let(:attributes) { { 'mime_type_ssi' => type } }

        it { is_expected.to be_video }
      end
    end
  end

  describe '#collection_ids' do
    context 'when the object belongs to collections' do
      let(:attributes) do
        { id: '123',
          title_tesim: ['A generic work'],
          collection_ids_tesim: ['123', '456', '789'] }
      end

      its(:collection_ids) { is_expected.to eq ['123', '456', '789'] }
    end

    context 'when the object does not belong to any collections' do
      let(:attributes) do
        { id: '123',
          title_tesim: ['A generic work'] }
      end

      its(:collection_ids) { is_expected.to eq [] }
    end
  end

  describe "#height" do
    let(:attributes) { { height_is: '444' } }

    its(:height) { is_expected.to eq '444' }
  end

  describe "#width" do
    let(:attributes) { { width_is: '555' } }

    its(:width) { is_expected.to eq '555' }
  end

  context "when exporting in endnote format" do
    let(:attributes) { { id: "1234" } }

    its(:endnote_filename) { is_expected.to eq("1234.endnote") }
  end

  describe "#admin_set?" do
    let(:attributes) { { 'has_model_ssim' => 'AdminSet' } }

    it { is_expected.to be_admin_set }
  end

  describe "#collection?" do
    let(:attributes) { { 'has_model_ssim' => Hyrax.config.collection_model } }

    it { is_expected.to be_collection }
  end

  describe "#work?" do
    let(:attributes) { { 'has_model_ssim' => 'GenericWork' } }

    it { is_expected.to be_work }
  end

  describe "#collection_type_gid?" do
    let(:attributes) do
      { 'collection_type_gid_ssim' => 'gid://internal/hyrax-collectiontype/5' }
    end

    its(:collection_type_gid) do
      is_expected.to eq 'gid://internal/hyrax-collectiontype/5'
    end
  end

  describe "controlled vocabulary fields" do
    let(:attributes) {
      {
          "creator_tesim" => ["https://id.worldcat.org/fast/680664"],
          "creator_label_tesim" => ["Foo"],
          "contributor_tesim" => ["http://id.worldcat.org/fast/549011"],
          "contributor_label_tesim" => ["Bar"],
          "subject_tesim" => ["http://id.worldcat.org/fast/1616727"],
          "subject_label_tesim" => ["An interesting subject"],
          "provider_tesim" => ["https://id.worldcat.org/fast/977265"],
          "provider_label_tesim" => ["Internet industry"],
          "physical_repository_tesim" => ["https://id.worldcat.org/fast/522461"],
          "physical_repository_label_tesim" => ["University of Victoria (B.C.). Library"],
          "geographic_coverage_tesim" => ["https://id.worldcat.org/fast/1214700"],
          "geographic_coverage_label_tesim" => ["British Columbia--Victoria"],
          "genre_tesim" => ["https://vocab.getty.edu/aat/300026096"],
          "genre_label_tesim" => ["exhibition catalogs"]
      }
    }

    its(:creator) { is_expected.to eq ["https://id.worldcat.org/fast/680664"] }
    its(:creator_label) { is_expected.to eq ["Foo"] }
    its(:contributor) { is_expected.to eq ["http://id.worldcat.org/fast/549011"] }
    its(:contributor_label) { is_expected.to eq ["Bar"] }
    its(:subject) { is_expected.to eq ["http://id.worldcat.org/fast/1616727"] }
    its(:subject_label) { is_expected.to eq ["An interesting subject"] }
    its(:provider) { is_expected.to eq ["https://id.worldcat.org/fast/977265"] }
    its(:physical_repository) { is_expected.to eq ["https://id.worldcat.org/fast/522461"] }
    its(:physical_repository_label) { is_expected.to eq ["University of Victoria (B.C.). Library"] }
    its(:geographic_coverage) { is_expected.to eq ["https://id.worldcat.org/fast/1214700"] }
    its(:geographic_coverage_label) { is_expected.to eq ["British Columbia--Victoria"] }
    its(:genre) { is_expected.to eq ["https://vocab.getty.edu/aat/300026096"] }
    its(:genre_label) { is_expected.to eq ["exhibition catalogs"] }
  end

  describe 'other Vault custom attributes' do
    let(:attributes) {
      {
          "alternative_title_tesim" => ["Alternative TItle"],
          "edition_tesim" => ["1st edition"],
          "coordinates_tesim" => ["-42.00945, 104.55527"],
          "chronological_coverage_tesim" => ["1927/1930"],
          "extent_tesim" => ["129 pages"],
          "additional_physical_characteristics_tesim" => ["Black leather binding"],
          "has_format_tesim" => ["Book"],
          "collection_tesim" => ["A Book Collection"],
          "provenance_tesim" => ["From XXX estate"],
          "sponsor_tesim" => ["Sponsor"],
          "format_tesim" => ["Text"],
          "archival_item_identifier_tesim" => ["zzz"],
          "fonds_title_tesim" => ["ZZZ fonds"],
          "fonds_creator_tesim" => ["Snorlax"],
          "fonds_description_tesim" => ["A fonds description"],
          "fonds_identifier_tesim" => ["ZZZ"],
          "is_referenced_by_tesim" => ["Sleepy"],
          "date_digitized_tesim" => ["2024-01-20"],
          "date_created_tesim" => ["1930"],
          "transcript_tesim" => ["A transcript"],
          "technical_note_tesim" => ["Digitized on TTI scanner"],
          "year_tesim" => ["1930"],
          "year_range_tesim" => ["1927, 1928, 1929, 1930"],
          "full_text_tesim" => ["Zzzzzzzzzzzzzzz"]
      }

      its(:alternative_title) { is_expected.to be ["Alternative Title"] }
      its(:edition) { is_expected.to be ["1st edition"] }
      its(:coordinates) { is_expected.to be ["-42.00945, 104.55527"] }
      its(:chronological_coverage) { is_expected.to be ["1927/1930"] }
      its(:extent) { is_expected.to eq ["129 pages"] }
      its(:additional_physical_characteristics) { is_expected.to eq ["Black leather binding"] }
      its(:has_format) { is_expected.to eq ["Book"] }
      its(:collection) { is_expected.to eq ["A Book Collection"] }
      its(:provenance) { is_expected.to eq ["From XXX estate"] }
      its(:sponsor) { is_expected.to eq ["Sponsor"] }
      its(:format) { is_expected.to eq ["Text"] }
      its(:archival_item_identifier) { is_expected.to eq ["zzz"] }
      its(:fonds_title) { is_expected.to eq ["ZZZ fonds"] }
      its(:fond_creator) { is_expected.to eq ["Snorlax"] }
      its(:fond_description) { is_expected.to eq ["A fonds description"] }
      its(:fonds_identifier) { is_expected.to eq ["ZZZ"] }
      its(:is_referenced_by) { is_expected.to eq ["Sleepy"] }
      its(:date_digitized) { is_expected.to eq ["2024-01-20"] }
      its(:date_created) { is_expected.to eq ["1930"] }
      its(:transcript) { is_expected.to eq ["A transcript"] }
      its(:technical_note) { is_expected.to eq ["Digitized on TTI scanner"] }
      its(:year) { is_expected.to eq ["1930"] }
      its(:year_range) { is_expected.to eq ["1927, 1928, 1929, 1930"] }
      its(:full_text) { is_expected.to eq ["Zzzzzzzzzzzzzzz"] }
    }
  end

  describe 'in_scua?' do
    subject { document.in_scua? }

    context 'when filled in' do
      let(:attributes) { { "in_scua_bsi" => true } }

      it { is_expected.to be true }
    end

    context 'when blank' do
      let(:attributes) { {} }
      
      it { is_expected.to be_nil }
    end
  end

  describe 'doi' do
    context 'when DOI is present' do
      let(:attributes) { { "doi_ssi" => "https://doi.org/XX.xxxx/yyyyyy" } }

      its(:doi) { is_expected.to be "https://doi.org/XX.xxxx/yyyyyy" }
    end

    context 'when blank' do
      let(:attributes) { {} }

      its(:doi) { is_expected.to eq [] }
    end
  end

  describe 'current_file_version' do
    let(:attributes) { { "current_file_version_ssi" => "file_id:version2" } }

    its(:current_file_version) { is_expected.to eq "file_id:version2" }
  end

  describe 'field_semantics' do
    subject { described_class.field_semantics }

    it 'returns the expected hash' do
      expect(subject).to eq({
           contributor: 'contributor_label_tesim',
           coverage: 'oai_dc_coverage_tesim',
           creator: 'creator_label_tesim',
           date: 'date_created_tesim',
           description: 'description_tesim',
           format: 'extent_tesim',
           identifier: 'identifier_tesim',
           language: 'language_tesim',
           publisher: 'publisher_tesim',
           relation: 'oai_dc_relation_tesim',
           rights: 'rights_statement_tesim',
           source: 'physical_repository_label_tesim',
           subject: 'subject_label_tesim',
           title: 'title_tesim',
           type: 'oai_dc_type_tesim',
           thumbnail_path: 'thumbnail_path_ss',
           model: 'has_model_ssim'})
    end
  end

  describe 'filename' do
    context 'when document/object has an import url' do
      let(:attributes) { { "import_url_ssim" => ["/path/to/local/file.txt"] } }

      its(:filename) { is_expected.to eq "file.txt" }
    end

    context 'when there is no import url' do
      let(:attributes) { {} }

      its(:filename) { is_expected.to be_nil }
    end
  end

  describe 'last_modified' do
    let(:attributes) { { "timestamp" => "2023-09-11T18:25:47.446Z" } }

    it 'uses the timestamp' do
      expect(subject.last_modified).to eq "2023-09-11T18:25:47.446Z"
    end
  end
end
