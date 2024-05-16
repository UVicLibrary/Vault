# frozen_string_literal: true
require 'iiif_manifest'

# rubocop:disable RSpec/SubjectStub
RSpec.describe VaultFileSetPresenter do
  subject(:presenter) { described_class.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { Ability.new(user) }
  let(:attributes) { file.to_solr }

  let(:file) do
    build(:file_set,
          id: '123abc',
          user: user,
          title: ["File title"],
          depositor: user.user_key,
          label: "filename.tif")
  end
  let(:user) { create(:admin) }

  describe "#user_can_perform_any_action?" do
  subject { presenter.user_can_perform_any_action? }
  let(:current_ability) { ability }
  let(:parent_presenter) { VaultWorkShowPresenter.new(SolrDocument.new, ability) }


  before do
    allow(presenter).to receive(:parent).and_return(parent_presenter)
  end

  context 'when user can perform at least 1 action' do
    before do
      expect(current_ability).to receive(:can?).with(:edit, presenter.id).and_return false
      expect(current_ability).to receive(:can?).with(:destroy, presenter.id).and_return false
      allow(current_ability).to receive(:can?).with(:download, presenter.id).and_return true
    end

    it 'is deprecated' do
      expect(Deprecation).to receive(:warn)
      subject
    end

    it { is_expected.to be true }
  end

  context 'when user cannot perform any action' do
    before do
      expect(current_ability).to receive(:can?).with(:edit, presenter.id).and_return false
      expect(current_ability).to receive(:can?).with(:destroy, presenter.id).and_return false
      allow(current_ability).to receive(:can?).with(:download, presenter.id).and_return false
    end

    it { is_expected.to be false }
  end
  end

end