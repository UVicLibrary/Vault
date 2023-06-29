# frozen_string_literal: true
RSpec.describe VaultDataCiteRegistrar do

  let(:registrar) { described_class.new }
  let(:username) { 'username' }
  let(:password) { 'password' }
  let(:prefix) { '10.1234' }
  let(:client) { Hyrax::DOI::DataCiteClient.new(username: username, password: password, prefix: prefix, mode: :test) }
  let(:draft_doi) { "#{prefix}/draft-doi" }
  let(:work) { GenericWork.new(attributes) }
  let(:attributes) do
    {
        title: [title],
        creator: [creator],
        publisher: [publisher],
        description: [description],
        contributor: [""],
        doi: doi,
        doi_status_when_public: "findable"
    }
  end

  let(:title) { 'Moomin' }
  let(:creator) { 'Tove Jansson' }
  let(:publisher) { 'Schildts' }
  let(:description) { 'Swedish comic about the adventures of the residents of Moominvalley.' }
  let(:doi) { [draft_doi] }

  before do
    Hyrax::DOI::DataCiteRegistrar.username = username
    Hyrax::DOI::DataCiteRegistrar.password = password
    Hyrax::DOI::DataCiteRegistrar.prefix = prefix
    Hyrax::DOI::DataCiteRegistrar.mode = :test
    allow(registrar).to receive(:client).and_return(client)
    allow(registrar).to receive(:work_to_datacite_xml).and_call_original
  end

  describe "#register!" do

    before do
      # Do not actually make calls to DataCite
      # https://support.datacite.org/docs/testing-guide
      allow(client).to receive(:put_metadata).with(any_args)
      allow(client).to receive(:register_url).with(any_args)
      allow(client).to receive(:delete_metadata).with(any_args)
    end

    context "when doi is supplied" do
      let(:identifier) { "<identifier identifierType=\"DOI\">#{draft_doi}</identifier>" }

      it "uses the existing doi" do
        expect(registrar).to receive(:work_to_datacite_xml).with(work, draft_doi).and_return(a_string_including(identifier))
        expect(registrar.register!(object: work).identifier).to eq draft_doi
      end
    end

    context "when doi is nil" do

      let(:doi) { nil }
      let(:other_doi) { "#{prefix}/other-doi" }
      let(:identifier) { "<identifier identifierType=\"DOI\">#{other_doi}</identifier>" }

      before do
        allow(client).to receive(:create_draft_doi).and_return(other_doi)
      end

      it "submits the draft doi" do
        expect(registrar).to receive(:work_to_datacite_xml).with(work, other_doi).and_return(a_string_including(identifier))
        expect(registrar.register!(object: work).identifier).to eq other_doi
      end
    end

    context "when the work's doi_when_public_status is findable and it is public" do
      before do
        work.visibility = 'open'
        allow(client).to receive(:register_url).with(any_args)
      end

      it 'registers the URL and does not call delete_metadata' do
        expect(client).to receive(:register_url)
        expect(client).not_to receive(:delete_metadata)
        registrar.register!(object: work)
      end
    end
  end

  describe "#work_to_datacite_xml" do
    context "when the work has blank attributes" do
      let(:contributor_tag) { "<contributors>" }
      let(:subject_tag) { "<subjects>" }

      it "omits the blank attributes from the DataCite metadata" do
        expect(registrar.public_send(:work_to_datacite_xml, work, draft_doi)).not_to include(contributor_tag, subject_tag)
      end
    end
  end

end