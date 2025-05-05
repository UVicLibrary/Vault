RSpec.describe ReindexNestedMembersJob do

  let(:collection) { build(:collection_lw, title: ['Parent Collection']) }
  let(:subcollection) { build(:collection_lw, title: ['Subcollection']) }
  let(:work) { build(:generic_work) }

  before do
    work.member_of_collections = [subcollection]
    [subcollection, work].each(&:save!)
  end

  describe 'when a nesting relationship changes' do

    before do
      subcollection.member_of_collections = [collection]
      subcollection.save!
      collection.save!
    end

    it "indexes parent ids into nested_member_of_collections_ssim" do
      expect {
        described_class.perform_now(collection.id)
        perform_enqueued_jobs
      }.to change { SolrDocument.find(work.id)['nested_member_of_collections_ssim'] }
                      .from(['Subcollection'])
                      .to(match_array(['Parent Collection', 'Subcollection']))
      expect(SolrDocument.find(subcollection.id)['nested_member_of_collections_ssim']).to eq ['Parent Collection']
    end
  end

end