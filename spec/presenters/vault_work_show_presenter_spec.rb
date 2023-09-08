# frozen_string_literal: true
RSpec.describe VaultWorkShowPresenter do
  subject(:presenter) { described_class.new(solr_document, ability, request) }
  let(:ability) { double Ability }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { double(remote_ip: "111.11.11") }
  let(:account) { Account.new }

  let(:attributes) do
    {
      "creator_label_tesim" => ['University of Victoria (B.C.). Library'],
      "creator_tesim" => ['http://id.worldcat.org/fast/522461'],
      "date_created_tesim" => ['an unformatted date'],
      "extent_tesim" => ["20 pages"]
    }
  end

  # We need to set the right value in Hyrax.config.iiif_metadata_fields
  before do
    allow(Account).to receive(:find_by).and_return(account)
    allow(account).to receive(:cname).and_return("vault")
  end

  # Delegate "label" field methods
  it { is_expected.to delegate_method(:provider_label).to(:solr_document) }
  it { is_expected.to delegate_method(:creator_label).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near_label).to(:solr_document) }
  it { is_expected.to delegate_method(:subject_label).to(:solr_document) }
  it { is_expected.to delegate_method(:contributor_label).to(:solr_document) }
  it { is_expected.to delegate_method(:physical_repository_label).to(:solr_document) }
  it { is_expected.to delegate_method(:genre_label).to(:solr_document) }
  it { is_expected.to delegate_method(:geographic_coverage_label).to(:solr_document) }

  it { is_expected.to delegate_method(:geographic_coverage).to(:solr_document) }
  it { is_expected.to delegate_method(:genre).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:depositor).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:keyword).to(:solr_document) }
  it { is_expected.to delegate_method(:admin_set).to(:solr_document) }
  it { is_expected.to delegate_method(:chronological_coverage).to(:solr_document) }
  it { is_expected.to delegate_method(:thumbnail_path).to(:solr_document) }

  it "includes DOI and DataCite DOI behaviour" do
    expect(presenter.class.ancestors).to include(Hyrax::DOI::DOIPresenterBehavior, Hyrax::DOI::DataCiteDOIPresenterBehavior)
  end

  describe '#downloadable?' do
    let(:work) { GenericWork.new(downloadable: true) }
    before { allow(GenericWork).to receive(:find).and_return(work) }

    it "returns the downloadable attribute of the work" do
      expect(subject.downloadable?).to be true
    end
  end

  describe '#manifest_metadata' do
    it 'returns an array of hashes like { "label" => "...", "value" => "..." }' do
      result = [
          { "label" => "Creator label", "value" => ['University of Victoria (B.C.). Library'] },
          { "label" => "Creator", "value" => ['http://id.worldcat.org/fast/522461'] },
          { "label" => "Extent", "value" => ['20 pages'] },
          { "label" => "Date created", "value" => ['an unformatted date'] }
      ]
      expect(subject.manifest_metadata).to match_array(result)
    end
  end

  describe 'authorized_item_ids' do
    let(:subject) { presenter.send(:authorized_item_ids) }
    let(:ids_list) { (0..5).map { |i| "item#{i}" } }
    let(:ability) { double "Ability" }
    let(:current_ability) { ability }
    let(:member_presenter_factory) { instance_double(Hyrax::MemberPresenterFactory, ordered_ids: items_list) }

    before do
      allow(presenter).to receive(:ordered_ids).and_return(ids_list)
      allow(Flipflop).to receive(:hide_private_items?).and_return(true)

      allow(current_ability).to receive(:can?).with(:read, 'item0').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item1').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item2').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item3').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item4').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item5').and_return true

      allow(Hyrax::SolrService).to receive(:search_by_id).with(any_args).and_return({ 'visibility_ssi' => "authenticated" })
    end

    context 'when IP is on campus' do
      let(:fake_ip) { "111.11.11" }

      before do
        allow(Settings).to receive(:allowed_ip_ranges).and_return(Array.wrap(fake_ip))
        allow(IPAddr).to receive(:new).with(any_args).and_return(fake_ip)
      end

      it "allows access to items it can't read otherwise" do
        expect(subject.size).to eq 6
        expect(subject).to eq ids_list
      end
    end

    context 'when IP is off campus' do
      let(:fake_ip1) { "111.11.11" }
      let(:fake_ip2) { "222.22.22" }

      before do
        allow(Settings).to receive(:allowed_ip_ranges).and_return(Array.wrap(fake_ip2))
        allow(IPAddr).to receive(:new).with(fake_ip1).and_return(fake_ip1)
        allow(IPAddr).to receive(:new).with(fake_ip2).and_return(fake_ip2)
      end

      it "does not allow access to items it can't read" do
        expect(subject.size).to eq 4
        expect(subject).to include('item0','item2','item4', 'item5')
        expect(subject).not_to include('item1','item3')
      end
    end
  end
end
