RSpec.describe NestedWorksSearchService do

  subject(:builder) do
    described_class.new(scope: scope,
                        collection: parent_collection,
                        params: params)
  end

  let(:params) { ActionController::Parameters.new(id: parent_collection.id) }

  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }
  let!(:subcollection) { create(:public_collection_lw, member_of_collections: [parent_collection], collection_type_settings: [:nestable]) }

  let!(:parent_collection) { create(:public_collection_lw, collection_type_settings: [:nestable]) }

  let!(:work1) { create(:generic_work, date_created: ["1990"], title: ["Title A"], member_of_collections: [parent_collection]) }
  let!(:work2) { create(:generic_work, date_created: ["1990"], title: ["Title B"], member_of_collections: [parent_collection]) }
  let!(:work3) { create(:generic_work, date_created: ["1989"], title: ["Title C"], member_of_collections: [subcollection]) }
  let!(:work4) { create(:generic_work) }

  describe "#available_member_works" do

    context 'when sort is not specified' do

      it 'returns works from collection & subcollections with default sorting' do
        ids = builder.available_member_works.response[:docs].map { |work| work[:id] }
        expect(ids).to eq([work3.id, work1.id, work2.id])
      end

    end

    context 'when sort is specified' do

      let(:params) { ActionController::Parameters.new(id: parent_collection.id,
                                                      sort: "title_sort_ssi asc") }

      it 'returns works from collection & subcollections, sorted as specified' do
        ids = builder.available_member_works.response[:docs].map { |work| work[:id] }
        expect(ids).to eq([work1.id, work2.id, work3.id])
      end

    end

  end

end