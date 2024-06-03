RSpec.describe ToggleDownloadsJob do
  let(:collection) { create(:collection_lw) }
  let(:user_email) { create(:user).email }
  let(:access) { described_class.new.send(:public_download_access) }
  let(:work) { create(:generic_work) }

  before do
    work.member_of_collections << collection
    work.save!
  end

  context 'when enabling public downloads' do
    let(:downloadable) { "true" }

    context 'with a work that already has the correct permissions' do

      before do
        work.permissions_attributes = work.permissions.map(&:to_hash) << access
        work.save!
      end

      it 'does not save the work' do
        expect(work).not_to receive(:save!)
        described_class.perform_now(collection.id, user_email, downloadable)
      end
    end

    context 'with a work that needs changing' do
      it "adds public download access to members' permissions" do
        described_class.perform_now(collection.id, user_email, downloadable)
        work.reload
        expect(work.permissions.map(&:to_hash)).to include access
        expect(SolrDocument.find(work.id)["download_access_group_ssim"]).to eq ["public"]
      end
    end
  end

  context 'when disabling public downloads' do
    let(:downloadable) { "false" }

    context 'with a work that already has the correct permissions' do

      it 'does not save the work' do
        expect(work).not_to receive(:save!)
        described_class.perform_now(collection.id, user_email, downloadable)
      end
    end

    context 'with a work that needs changing' do
      before do
        work.permissions_attributes = work.permissions.map(&:to_hash) << access
        work.save!
      end

      it "removes public download access from members' permissions" do
        described_class.perform_now(collection.id, user_email, downloadable)
        work.reload
        expect(work.permissions.map(&:to_hash)).not_to include access
        expect(SolrDocument.find(work.id)).not_to have_key("download_access_group_ssim")
      end
    end

  end
end