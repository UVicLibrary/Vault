RSpec.describe FastUpdateHelper, type: :helper do

  describe "#render_complete_cell" do

    let(:change) { FastUpdate::Change.new(complete: true, count: 10) }
    subject { helper.render_complete_cell(change) }

    context "when a change's complete attribute is true" do

      context "and its action is 'replace'" do
        before { change.action = "replace" }

        it "displays a success message with the count" do
          expect(subject).to eq("<span class='badge badge-success'>Success</span>  10 replacement(s) made.")
        end
      end

      context "and its action is 'delete'" do
        before { change.action = "delete" }

        it "displays a success message" do
          expect(subject).to eq("<span class='badge badge-success'>Success</span>")
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
        expect(subject).to eq('<span class="badge badge-danger">Error</span> Contact administrator for details.')
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

end