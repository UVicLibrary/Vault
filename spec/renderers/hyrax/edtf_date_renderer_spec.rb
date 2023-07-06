# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::EdtfDateRenderer do
  let(:field) { :chronological_coverage }
  let(:renderer) { described_class.new(field, values) }
  let(:values) { ['1993-01', 'unknown'] }

  subject { renderer.render_dl_row.gsub(/\s+/, "") }

  let(:dl_content) do
    %(
      <dt>Chronological coverage</dt>
      <dd>
        <ul class='tabular'>
          <li class="attribute attribute-chronological_coverage">
            January 1993
          </li>
          <li class="attribute attribute-chronological_coverage">
            unknown
          </li>
        </ul>
      </dd>
    ).gsub(/\s+/, "")
  end

  describe "#attribute_to_html" do

    context 'with valid edtf dates' do
      it { expect(subject).to eq(dl_content) }
    end

    context 'with invalid edtf dates' do
      let(:values) { ['something invalid'] }
      let(:dl_content) {
        %(
          <dt>Chronological coverage</dt>
          <dd>
            <ul class='tabular'>
              <li class="attribute attribute-chronological_coverage">
                something invalid
              </li>
            </ul>
          </dd>
        ).gsub(/\s+/, "")
      }

      it { expect(subject).to eq(dl_content) }
    end

  end
end
