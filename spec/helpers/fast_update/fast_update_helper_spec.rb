RSpec.describe FastUpdateHelper, type: :helper do

  describe "#render_complete_cell" do

    let(:change) { FastUpdate::Change.new(complete: true, count: 10) }
    subject { helper.render_complete_cell(change) }

    context "when a change's complete attribute is true" do

      context "and its action is 'replace'" do
        before { change.action = "replace" }

        it "displays a success message with the count" do
          expect(subject).to eq("<span class='label label-success'>Success</span>  10 replacement(s) made.")
        end
      end

      context "and its action is 'delete'" do
        before { change.action = "delete" }

        it "displays a success message" do
          expect(subject).to eq("<span class='label label-success'>Success</span>")
        end
      end
    end

    context "when a change's complete attribute is nil" do
      before { change.complete = nil }
      it { is_expected.to eq("No") }
    end

    context "when there was an error" do
      before { change.complete = false }

      it "displays an error message" do
        expect(subject).to eq('<span class="label label-danger">Error</span> Contact administrator for details.')
      end
    end
  end

  describe "#render_field_names" do
    let(:document) { { 'has_model_ssim' => ['GenericWork'],
                      'creator_tesim' => ['http://id.worldcat.org/fast/549011'],
                      'provider_tesim' => ['http://id.worldcat.org/fast/549011'] } }
    subject { helper.render_field_names(document, "http://id.worldcat.org/fast/549011") }

    before do
      allow(helper).to receive(:solr_field_names).and_return({ "GenericWork" => ['creator_tesim', 'provider_tesim'] })
    end

    it { is_expected.to eq("Creator, Provider") }
  end

  describe "#render_facet_value" do
    let(:item) { double(:value => 'A', :hits => 10) }
    let(:expected_html) { '<span class="facet-label"><a class="facet_select" data-remote="true" href="/fast_update/search_preview">Z</a></span><span class="facet-count">10</span>' }

    before do
      allow(helper).to receive(:facet_display_value).with('simple_field', item).and_return('Z')
      allow(helper).to receive(:path_for_facet).with(any_args).and_return("/fast_update/search_preview")
      allow(helper).to receive(:render_facet_count).with(10).and_call_original
    end

    it "renders a span and a remote link" do
      expect(helper.render_facet_value('simple_field', item)).to eq(expected_html)
    end
  end

  describe "render constraints behavior" do

    let(:config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field "member_of_collections_ssim", limit: 5, label: "Collection"
      end
    end

    describe "#render_filter_element" do
      let(:path) { Blacklight::SearchState.new(params, config, controller) }
      let(:facet_config) { config.facet_fields.first.last }
      let(:params) { ActionController::Parameters.new old_uri: "http://id.worldcat.org/fast/549011" }
      subject { helper.render_filter_element('member_of_collections_ssim', 'Test Collection', path) }

      before do
        controller.request.path_parameters[:controller] = 'fast_update/changes'
        allow(helper).to receive(:facet_configuration_for_field).with('member_of_collections_ssim').and_return(facet_config)
        allow(helper).to receive(:facet_field_label).with(facet_config.key).and_return(facet_config.label)
      end

      it "has a remote link to the fast update search preview path" do
        expect(subject).to have_link "Remove constraint Collection: Test Collection", href: "/fast_update/search_preview?old_uri=http%3A%2F%2Fid.worldcat.org%2Ffast%2F549011"
        expect(subject).to match(/data-remote=\"true\"/)
        expect(subject).to have_selector ".filterName", text: 'Collection'
      end
    end

  end
end