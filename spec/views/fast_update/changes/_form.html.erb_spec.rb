RSpec.describe 'fast_update/changes/_form.html.erb', type: :view do
  let(:change) { FastUpdate::Change.new }

  describe "it renders the page" do

    before do
      allow(view).to receive(:fast_update_search_preview_path).and_return("/fast_update/search_preview")
      assign(:change, change)
      render
    end

    it "renders text inputs and radio buttons" do
      expect(rendered).to have_selector("input#old-label")
      expect(rendered).to have_selector("input#fast_update_change_old_uri")
      expect(rendered).to have_selector("input#new_labels_and_uris_0")
      expect(rendered).to have_selector("input#fast_update_change_new_uris", visible: false)
      expect(rendered).to have_selector("input#fast_update_change_collection_id")

      expect(rendered).to have_selector('input[type="radio"]#fast_update_change_action_delete')
      expect(rendered).to have_selector('input[type="radio"]#fast_update_change_action_replace')
      expect(rendered).to have_selector('input[type="radio"]#fast_update_change_collection_id_all')
      expect(rendered).to have_selector('input[type="radio"]#fast_update_change_collection_id_')
    end

    it "renders search preview and submit buttons" do
      expect(rendered).to have_selector('a#fast-update-search-preview[data-remote="true"]')
      expect(rendered).to have_selector('input#fast-update-submit-button[type="submit"]')
    end
  end

end