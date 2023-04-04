# frozen_string_literal: true
RSpec.describe FastUpdate::ChangesController, type: :controller do
  # Create and index actions are in spec/requests/fast_update/changes_spec.rb

  describe "#search_builder_class" do
    subject { controller.search_builder_class }
    it { is_expected.to eq FastUpdate::UriSearchBuilder }
  end

  describe "#view context" do
    it "includes helper methods defined in FastUpdateHelper" do
      expect(controller.view_context).to respond_to(:render_complete_cell)
    end
  end

end