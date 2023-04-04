RSpec.describe "FastUpdate::Changes", type: :request do

  let(:admin) { create(:admin) }

  describe "#create" do

    let(:change_params) { { old_label: "",
                            old_uri: "http://id.worldcat.org/fast/549011       ",
                            action: "delete",
                            new_labels_and_uris: {"0"=>{"uri"=>""}},
                            collection_id: "all" } }

    before do
      allow(admin).to receive(:groups).and_return(["admin"])
      sign_in admin
    end

    context "with valid parameters" do

      before { post fast_update_changes_path, params: { fast_update_change: change_params } }

      it "creates a new FastUpdate::Change" do
        expect(FastUpdate::Change.count).to eq(1)
      end

      it "saves with the proper attributes" do
        change = FastUpdate::Change.first
        expect(change.old_label).to eq("No label available")
        expect(change.old_uri).to eq("http://id.worldcat.org/fast/549011")
        expect([change.new_labels, change.new_uris]).to all(be_blank)
        expect(change.collection_id).to eq("all")
      end

      it "enqueues a ReplaceOrDeleteUriJob" do
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq(1)
      end

      it "redirects to the index page" do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to("http://www.example.com/fast_update/replace_uri?locale=en")
      end

    end


    context "with invalid parameters" do
      # This is invalid because we need new uris/labels to replace the old
      let(:invalid_params) { change_params.merge(action: "replace") }
      before { post fast_update_changes_path, params: { fast_update_change: invalid_params } }

      it "redirects to the index page with an error message" do
        expect(response).to have_http_status(302)
        expect(flash[:error]).to eq(["New uris must be selected to replace the old one"])
        expect(response).to redirect_to("http://www.example.com/fast_update/replace_uri?locale=en")
      end
    end

  end

  describe "#index" do

    let(:change_params) { { old_label: "Tiffany and Company",
                            old_uri: "http://id.worldcat.org/fast/549011",
                            action: "delete",
                            collection_id: "all" } }

    before do
      FastUpdate::Change.create(change_params)
      allow(admin).to receive(:groups).and_return(["admin"])
      sign_in admin
      get fast_update_replace_uri_path
    end

    it "renders the index template" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to render_template(:index)
    end

    it "gets a list of all changes" do
      expect(response.body).to include("Tiffany and Company")
      expect(response.body).to include("http://id.worldcat.org/fast/549011")
    end

    context "when the current user is not an admin" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "redirects to the homepage" do
        get fast_update_replace_uri_path
        expect(response).to have_http_status(302)
        expect(response).to redirect_to("http://www.example.com/?locale=en")
        follow_redirect!
      end
    end

  end

  describe "#search_preview" do

    let(:search_params) { ActionController::Parameters.new(
                              "old_uri"=>"http://id.worldcat.org/fast/549011",
                              "old_label"=>"Tiffany and Company",
                              "controller"=>"fast_update/changes",
                              "action"=>"search_preview") }

    before do
      allow(admin).to receive(:groups).and_return(["admin"])
      sign_in admin
      get fast_update_search_preview_path, params: search_params, xhr: true
    end

    it "renders the search_preview partial" do
      expect(response).to render_template("search_preview.js.erb")
      expect(response.body).to match(/Couldn't find any works with this URI./)
    end

  end
end