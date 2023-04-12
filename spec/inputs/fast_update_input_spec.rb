# frozen_string_literal: true

RSpec.describe 'FastUpdateInput', type: :input do

  let(:builder) { SimpleForm::FormBuilder.new(:fast_update_change, FastUpdate::Change.new, helper, {}) }
  let(:input) { FastUpdateInput.new(builder, :new_uris, :multi_value, {}) }

  describe '#build_field' do
    subject { input.send(:build_field, nil, 0) }

    it "has inputs with the expected classes" do
      expect(subject).to have_selector('input.form-control.multi-text-field')
      expect(subject).to have_selector('input.controlled_vocabulary', visible: false)
    end

    it "renders a text field for the new label" do
      expect(subject).to have_selector('input[name="fast_update_change[new_labels_and_uris][0][label]"][type="text"]')
    end

    it "creates a hidden field for the new uri" do
      expect(subject).to have_selector('input[name="fast_update_change[new_labels_and_uris][0][uri]"][type="hidden"]', visible: false)
    end

    context "when data is passed" do
      let(:options) { { input_html: { class: [], data: { 'autocomplete-url' => '/authorities/search' } } } }
      # input_for is defined in spec/support/input_support.rb
      subject { input_for(FastUpdate::Change.new, :new_uris, options) }

      it "preserves passed-in data" do
        expect(subject).to have_selector('input[data-autocomplete-url="/authorities/search"]', visible: false)
      end
    end
  end
end
