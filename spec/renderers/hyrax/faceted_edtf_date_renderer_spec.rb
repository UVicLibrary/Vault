# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::FacetedEdtfDateRenderer do
  let(:field) { :date_created }
  let(:renderer) { described_class.new(field, values, options) }
  let(:document) { double }
  let(:options) { { document: document } }
  let(:values) { ['1993-01', '1993/1995'] }

  subject { renderer.render_dl_row.gsub(/\s+/, "") }

  let(:dl_content) do
    %(
      <dt>Date created</dt>
      <dd>
        <ul class='tabular'>
          <li class="attribute attribute-date_created">
            <span itemprop="dateCreated">
              <a href="/catalog?range[year_range_isim][begin]=1993&amp;range[year_range_isim][end]=1993">January 1993</a>
            </span>
          </li>
          <li class="attribute attribute-date_created">
            <span itemprop="dateCreated">
              <a href="/catalog?range[year_range_isim][begin]=1993&amp;range[year_range_isim][end]=1995">1993 to 1995</a>
            </span>
          </li>
        </ul>
      </dd>
    ).gsub(/\s+/, "")
  end

  describe "#attribute_to_html" do

    context 'with valid edtf dates' do
      before do
        allow(Hyrax.config).to receive(:display_microdata?).and_return(true)
        allow(document).to receive(:year_range).and_return([1993, 1995])
      end

      it 'renders the correct HTML and links to the correct range query' do
        expect(subject).to eq(dl_content)
      end
    end

    context 'with invalid edtf dates' do
      let(:values) { ['something invalid'] }
      let(:dl_content) {
        %(
          <dt>Date created</dt>
          <dd>
            <ul class='tabular'>
              <li class="attribute attribute-date_created">
                <span itemprop="dateCreated">
                  <a href="/catalog?range[year_range_isim][missing]=true">something invalid</a>
                </span>
              </li>
            </ul>
          </dd>
        ).gsub(/\s+/, "")
      }

      it 'renders the correct HTML and links to a missing range query' do
        expect(subject).to eq(dl_content)
      end
    end

    context 'with unknown or no date' do
      let(:values) { ['unknown', 'no date'] }

      let(:dl_content) do
        %(
          <dt>Date created</dt>
          <dd>
            <ul class='tabular'>
              <li class="attribute attribute-date_created">
                <span itemprop="dateCreated">
                  <a href="/catalog?range[year_range_isim][missing]=true">unknown</a>
                </span>
              </li>
              <li class="attribute attribute-date_created">
                <span itemprop="dateCreated">
                  <a href="/catalog?range[year_range_isim][missing]=true">no date</a>
                </span>
              </li>
            </ul>
          </dd>
        ).gsub(/\s+/, "")
      end

      it 'renders the correct HTML and links to a missing range query' do
        expect(subject).to eq(dl_content)
      end
    end
  end
end
