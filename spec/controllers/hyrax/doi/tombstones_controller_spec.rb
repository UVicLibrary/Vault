RSpec.describe Hyrax::DOI::TombstonesController, type: :controller do

  let(:prefix) { '10.1234' }
  let(:doi) { '10.1234/abcd-efgh' }
  let(:params) { { doi: doi, hyrax_id: "efgh" } }

  routes { Rails.application.routes }

  before do
    Hyrax.config.identifier_registrars = { datacite: Hyrax::DOI::DataCiteRegistrar }
    Hyrax::DOI::DataCiteRegistrar.mode = :test
    Hyrax::DOI::DataCiteRegistrar.prefix = prefix
    Hyrax::DOI::DataCiteRegistrar.username = 'username'
    Hyrax::DOI::DataCiteRegistrar.password = 'password'
  end

  describe '#new' do

    it 'builds a new tombstone from params' do
      get :new, params: params
      expect(assigns[:tombstone].doi).to eq "10.1234/abcd-efgh"
      expect(assigns[:tombstone].hyrax_id).to eq "efgh"
    end

  end

  describe '#create' do
    let(:hyrax_id) { 'efgh' }
    let(:tombstone_params) { { tombstone: { doi: doi,
                                            hyrax_id: hyrax_id,
                                            reason: "rights or privacy restrictions" } } }
    let(:work) { GenericWork.new(id: hyrax_id) }
    let(:url) { "http://test.host/doi/tombstones/10.1234/abcd-efgh" }

    before do
      allow(ActiveFedora::Base).to receive(:find).with(hyrax_id).and_return(work)
      allow(work).to receive(:destroy!)

      stub_request(:put, URI.join(Hyrax::DOI::DataCiteClient::TEST_BASE_URL, "dois/", doi))
        .with(headers: { "Content-Type" => "application/vnd.api+json" },
              body: "{\"data\":{\"type\":\"dois\",\"attributes\":{\"event\":\"hide\",\"url\":\"#{url}\"}}}")
        .to_return(status: 200, body: "") # The body doesn't really matter because we don't use it
    end

    it 'creates a tombstone from params' do
      get :create, params: tombstone_params
      expect(Hyrax::DOI::Tombstone.all.count).to eq 1
      tombstone = Hyrax::DOI::Tombstone.last
      expect(tombstone.doi).to eq "10.1234/abcd-efgh"
      expect(tombstone.hyrax_id).to eq "efgh"
      expect(tombstone.reason).to eq "rights or privacy restrictions"
      expect(response).to redirect_to(CGI.unescape(routes.url_helpers.hyrax_doi_tombstone_path(doi: doi, locale: "en")))
    end

    it 'sends a request to the DataCite API' do
      expect_any_instance_of(Hyrax::DOI::DataCiteTombstoneClient).to receive(:create_tombstone_doi).with(doi)
      get :create, params: tombstone_params
    end

    it 'destroys the relevant work' do
      expect(work).to receive(:destroy!)
      get :create, params: tombstone_params
    end
  end

  describe '#show' do
    let!(:tombstone) { Hyrax::DOI::Tombstone.create(params.merge(reason: "rights or privacy restrictions")) }
    let(:metadata_response) {
      """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
        <resource schemaLocation=\"foo\">\n
          <identifier identifierType=\"DOI\">#{doi}</identifier>\n
        </resource>\n
      """
    }

    before do
      stub_request(:get, URI.join(Hyrax::DOI::DataCiteClient::TEST_MDS_BASE_URL, "metadata/", doi))
        .to_return(status: 200, body: metadata_response)
    end

    it 'sets @tombstone and @metadata, and renders the template' do
      get :show, params: { doi: doi }
      expect(assigns[:tombstone]).to eq tombstone
      expect(assigns[:metadata]).to eq({"schemaLocation"=>"foo",
        "identifier"=> {"identifierType"=>"DOI", "__content__"=>"10.1234/abcd-efgh"}})
      expect(response).to render_template(layout: 'hyrax')
    end
  end

end