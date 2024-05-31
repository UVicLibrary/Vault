# frozen_string_literal: true
RSpec.describe 'hyrax/generic_works/_attribute_rows.html.erb', type: :view do
  let(:url) { "http://example.com" }
  let(:rights_statement_uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
  let(:ability) { double }
  let(:work) do
    stub_model(GenericWork,
               id: "foo",
               related_url: [url],
               rights_statement: [rights_statement_uri])
  end
  let(:solr_document) do
    SolrDocument.new(has_model_ssim: 'GenericWork',
                     id: "foo",
                     rights_statement_tesim: [rights_statement_uri],
                     related_url_tesim: [url])
  end
  let(:presenter) { VaultWorkShowPresenter.new(solr_document, ability) }

  let(:page) do
    render 'hyrax/generic_works/attribute_rows', presenter: presenter
    Capybara::Node::Simple.new(rendered)
  end

  it 'shows external link with icon for related url field' do
    expect(page).to have_selector '.glyphicon-new-window'
    expect(page).to have_link(url)
  end

  it 'shows rights statement with link to statement URL' do
    expect(page).to have_link("In Copyright", href: rights_statement_uri)
  end

  context 'with a DOI' do

    let(:doi) { "10.0000/xxxx-xxxx" }
    let(:work) do
      stub_model(GenericWork,
                 id: "foo",
                 doi: doi)
    end
    let(:solr_document) do
      SolrDocument.new(has_model_ssim: 'GenericWork',
                       id: "foo",
                       doi_ssi: doi)
    end

    it 'renders the DOI as an external link' do
      expect(page).to have_link("https://doi.org/#{doi}")
      expect(page).to have_selector "a[href='https://doi.org/#{doi}'] .glyphicon-new-window"
    end
  end
end
