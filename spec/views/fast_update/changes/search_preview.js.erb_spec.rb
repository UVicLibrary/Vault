# frozen_string_literal: true
RSpec.describe 'fast_update/changes/search_preview.js.erb', type: :view do

  let(:response) { instance_double(Blacklight::Solr::Response, response: { 'numFound' => 1 }) }

  before do
    assign(:response, response)
    allow(view).to receive(:render).and_call_original
  end

  context 'with search results' do
    let(:doc_list) {  [SolrDocument.new] }

    before do
      allow(response).to receive(:docs).and_return(doc_list)
      stub_template 'fast_update/changes/_search_results.html.erb' => 'search results partial'
      render template: 'fast_update/changes/search_preview.js.erb',
             locals: { uri: "http://id.worldcat.org/fast/549011", label: "Tiffany and Company" }
    end

    it "renders the search results partial with the expected arguments" do
      expect(rendered).to have_content('search results partial')
      expect(view).to have_received(:render).with({
            partial: 'search_results',
            locals: { docs: doc_list,
                      uri: "http://id.worldcat.org/fast/549011",
                      label: "Tiffany and Company" } })
    end
  end

  context 'with no search results' do
    before do
      allow(response).to receive(:docs).and_return([])
      render
    end

    it "does not render the search results partial" do
      expect(view).not_to receive(:render).with(partial: "search_results")
    end
  end

end