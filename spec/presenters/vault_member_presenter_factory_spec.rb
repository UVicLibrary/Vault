# frozen_string_literal: true
RSpec.describe VaultMemberPresenterFactory do
  subject(:factory) { described_class.new(solr_document, ability, request) }

  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { {} }
  let(:ability) { double }
  let(:request) { double }
  let(:presenter_class) { double }

  describe "#member_presenters" do
    it 'is equal to VaultFileSetPresenter' do
      expect(described_class.file_presenter_class).to eq VaultFileSetPresenter
    end

    it 'is equal to VaultWorkPresenter' do
      expect(described_class.work_presenter_class).to eq VaultWorkShowPresenter
    end
  end
end