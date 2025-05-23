RSpec.describe VaultCollectionPresenter do
  describe ".terms" do
    subject { described_class.terms }
    it { is_expected.to eq [:total_viewable_items,
                            :modified_date] }
  end

  let(:collection) do
    build(:collection_lw,
          id: 'adc12v',
          description: ['a nice collection'],
          based_near: [Hyrax::ControlledVocabularies::Location.new("https://sws.geonames.org/6174041/")],
          title: ['A clever title'],
          keyword: ['neologism'],
          resource_type: ['http://purl.org/dc/dcmitype/Collection'],
          date_created: ['some date'])
  end
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  describe "collection type methods" do
    subject { presenter }

    it { is_expected.to delegate_method(:collection_type_is_nestable?).to(:collection_type).as(:nestable?) }
    it { is_expected.to delegate_method(:collection_type_is_brandable?).to(:collection_type).as(:brandable?) }
    it { is_expected.to delegate_method(:collection_type_is_discoverable?).to(:collection_type).as(:discoverable?) }
    it { is_expected.to delegate_method(:collection_type_is_sharable?).to(:collection_type).as(:sharable?) }
    it { is_expected.to delegate_method(:collection_type_is_share_applies_to_new_works?).to(:collection_type).as(:share_applies_to_new_works?) }
    it { is_expected.to delegate_method(:collection_type_is_allow_multiple_membership?).to(:collection_type).as(:allow_multiple_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_require_membership?).to(:collection_type).as(:require_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_workflow?).to(:collection_type).as(:assigns_workflow?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_visibility?).to(:collection_type).as(:assigns_visibility?) }

    it "sets a default value on subcollection_counts" do
      expect(subject.subcollection_count).to eq(0)
    end

    it { is_expected.to respond_to(:subcollection_count=).with(1).argument }

    it "provides the amount of subcollections when there are none" do
      subject.subcollection_count = nil
      expect(subject.subcollection_count).to eq(0)
    end

    it "provides the amount of subcollections when they exist" do
      expect(subject.subcollection_count = 5).to eq(5)
    end
  end

  describe '#collection_type' do
    let(:collection_type) { create(:collection_type) }

    describe 'when solr_document#collection_type_gid exists' do
      let(:collection) { build(:collection_lw, collection_type_gid: collection_type.gid) }
      let(:solr_doc) { SolrDocument.new(collection.to_solr) }

      it 'finds the collection type based on the solr_document#collection_type_gid if one exists' do
        expect(presenter.collection_type).to eq(collection_type)
      end
    end
  end

  describe "#resource_type" do
    subject { presenter.resource_type }

    it { is_expected.to eq ['http://purl.org/dc/dcmitype/Collection'] }
  end

  describe "#terms_with_values" do
    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
      allow(ability).to receive(:admin?).and_return(false)
    end

    it 'gives the list of terms that have values' do
      expect(presenter.terms_with_values)
          .to contain_exactly(:total_viewable_items, :modified_date)
    end
  end

  describe '#to_s' do
    subject { presenter.to_s }

    it { is_expected.to eq 'A clever title' }
  end

  describe "#title" do
    subject { presenter.title }

    it { is_expected.to eq ['A clever title'] }
  end

  describe '#keyword' do
    subject { presenter.keyword }

    it { is_expected.to eq ['neologism'] }
  end

  describe "#based_near" do
    subject { presenter.based_near }

    it { is_expected.to eq ["https://sws.geonames.org/6174041/"] }
  end

  describe '#to_key' do
    subject { presenter.to_key }

    it { is_expected.to eq ['adc12v'] }
  end

  describe "#total_items", :clean_repo do
    subject { presenter.total_items }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with work" do
      let!(:work) { create(:work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_items", :clean_repo do
    subject { presenter.total_viewable_items }

    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
      allow(ability).to receive(:admin?).and_return(false)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work" do
      let!(:work) { create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:work) { build(:private_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public collection" do
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 2 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_works", :clean_repo do
    subject { presenter.total_viewable_works }

    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
      allow(ability).to receive(:admin?).and_return(false)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work" do
      let!(:work) { create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_collections", :clean_repo do
    subject { presenter.total_viewable_collections }

    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
      allow(ability).to receive(:admin?).and_return(false)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:subcollection) { build(:private_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public collection" do
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#parent_collection_count" do
    subject { presenter.parent_collection_count }

    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

    context('when parent_collections is nil') do
      before do
        allow(presenter).to receive(:parent_collections).and_return(nil)
      end

      it { is_expected.to eq 0 }
    end

    context('when parent_collections has no collections') do
      let(:parent_docs) { [] }

      it { is_expected.to eq 0 }
    end

    context('when parent_collections has collections') do
      let(:collection1) { build(:collection_lw, title: ['col1']) }
      let(:collection2) { build(:collection_lw, title: ['col2']) }
      let!(:parent_docs) { [collection1, collection2] }

      before do
        presenter.parent_collections = parent_collections
      end

      it { is_expected.to eq 2 }
    end
  end

  describe "#collection_type_badge" do
    let(:collection_type) { create(:collection_type) }
    before do
      allow(collection_type).to receive(:badge_color).and_return("#ffa510")
      allow(presenter).to receive(:collection_type).and_return(collection_type)
    end

    subject { presenter.collection_type_badge }

    it { is_expected.to eq "<span class=\"badge\" style=\"background-color: #ffa510;\">" + collection_type.title + "</span>" }
  end

  describe "#user_can_nest_collection?" do
    before do
      allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
    end

    subject { presenter.user_can_nest_collection? }

    it { is_expected.to eq true }
  end

  describe "#user_can_create_new_nest_collection?" do
    before do
      allow(ability).to receive(:can?).with(:create_collection_of_type, collection.collection_type).and_return(true)
    end

    subject { presenter.user_can_create_new_nest_collection? }

    it { is_expected.to eq true }
  end

  describe '#show_path' do
    subject { presenter.show_path }

    it { is_expected.to eq "/dashboard/collections/#{solr_doc.id}?locale=en" }
  end

  describe "banner_file" do
    let(:solr_doc) { SolrDocument.new(id: '123') }

    let(:banner_info) do
      CollectionBrandingInfo.new(
          collection_id: "123",
          filename: "banner.gif",
          role: "banner",
          target_url: ""
      )
    end

    let(:logo_info) do
      CollectionBrandingInfo.new(
          collection_id: "123",
          filename: "logo.gif",
          role: "logo",
          alt_txt: "This is the logo",
          target_url: "http://logo.com"
      )
    end

    it "banner check" do
      tempfile = Tempfile.new('my_file')
      banner_info.save(tempfile.path)
      expect(presenter.banner_file).to eq("/branding/123/banner/banner.gif")
    end

    it "logo check" do
      tempfile = Tempfile.new('my_file')
      logo_info.save(tempfile.path)
      expect(presenter.logo_record).to eq([{ file: "logo.gif", file_location: "/branding/123/logo/logo.gif", alttext: "This is the logo", linkurl: "http://logo.com" }])
    end
  end

  subject { presenter }

  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }

  describe '#managed_access' do
    context 'when manager' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(true)
      end
      it 'returns Manage label' do
        expect(presenter.managed_access).to eq 'Manage'
      end
    end

    context 'when depositor' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
      end
      it 'returns Deposit label' do
        expect(presenter.managed_access).to eq 'Deposit'
      end
    end

    context 'when manager' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:read, solr_doc).and_return(true)
      end
      it 'returns View label' do
        expect(presenter.managed_access).to eq 'View'
      end
    end
  end

  describe '#allow_batch?' do
    context 'when user cannot edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be false
      end
    end

    context 'when user can edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(true)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be true
      end
    end
  end

  describe '#user_can_feature_collections?' do

    context 'when user can create featured collections' do
      before do
        allow(ability).to receive(:can?).with(:create, FeaturedCollection).and_return(true)
      end
      it 'returns true' do
        expect(presenter.user_can_feature_collections?).to be true
      end
    end

    context "when user can't create featured collections" do
      before do
        allow(ability).to receive(:can?).with(:create, FeaturedCollection).and_return(false)
      end
      it 'returns false' do
        expect(presenter.user_can_feature_collections?).to be false
      end
    end
  end

  describe '#collection_featurable?' do

    context "when user can create featured collections" do
      let(:solr_doc) { SolrDocument.new(collection.to_solr) }

      before { allow(ability).to receive(:can?).with(:create, FeaturedCollection).and_return(true) }

      context "and solr document is public" do
        before { allow(solr_doc).to receive(:public?).and_return(true) }

        it "returns true" do
          expect(presenter.collection_featurable?).to be true
        end
      end

      context "and solr document is private" do
        before { allow(solr_doc).to receive(:public?).and_return(false) }

        it "returns false" do
          expect(presenter.collection_featurable?).to be false
        end
      end
    end

    context "when user can't create featured collections" do
      before { allow(ability).to receive(:can?).with(:create, FeaturedCollection).and_return(false) }

      it "returns false" do
        expect(presenter.collection_featurable?).to be false
      end
    end
  end

  describe '#display_feature_link?' do
    before { allow(ability).to receive(:can?).with(:create, FeaturedCollection).and_return(true) }

    context "when a featured collection can be added and collection is not featured" do
      let(:solr_doc) { SolrDocument.new(collection.to_solr) }

      before do
        allow(solr_doc).to receive(:public?).and_return(true)
      end
      it 'returns true' do
        expect(presenter.display_feature_link?).to be true
      end
    end

    context "when the collection is not featurable" do
      before { allow(presenter).to receive(:collection_featurable?).and_return(false) }

      it 'returns false' do
        expect(presenter.display_feature_link?).to be false
      end
    end

    context "when another collection cannot be featured" do
      before { allow(FeaturedCollection).to receive(:can_create_another?).and_return(false) }

      it 'returns false' do
        expect(presenter.display_feature_link?).to be false
      end
    end

    context 'when collection is already featured' do
      before { FeaturedCollection.create(collection_id: collection.id) }

      it 'returns false' do
        expect(presenter.display_feature_link?).to be false
      end
    end
  end

  describe '#display_unfeature_link?' do

    context 'when collection is not featured' do
      before { allow(presenter).to receive(:collection_featurable?).and_return(true) }

      it 'returns false' do
        expect(presenter.display_unfeature_link?).to be false
      end
    end

    context 'when collection is already featured' do
      before do
        allow(presenter).to receive(:collection_featurable?).and_return(true)
        FeaturedCollection.create(collection_id: collection.id)
      end

      it 'returns true' do
        expect(presenter.display_unfeature_link?).to be true
      end
    end

    context 'when collection is not featurable' do
      before { allow(presenter).to receive(:collection_featurable?).and_return(false) }

      it 'returns false' do
        expect(presenter.display_unfeature_link?).to be false
      end
    end
  end

  describe '#featured?' do

    context "when the collection isn't featured" do
      it 'returns false' do
        expect(presenter.featured?).to be false
      end
    end

    context 'when the collection is featured' do
      before { FeaturedCollection.create(collection_id: collection.id) }

      it 'returns true' do
        expect(presenter.featured?).to be true
      end
    end
  end

end