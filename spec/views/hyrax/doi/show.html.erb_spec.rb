RSpec.describe 'hyrax/doi/tombstones/show.html.erb', type: :view do
  let(:doi) { "10.1234/abcd-efgh" }
  let(:tombstone) { Hyrax::DOI::Tombstone.new(doi: doi, hyrax_id: "foobar", reason: "test") }
  let(:metadata) { { "titles" => { "title" => "A Title" } } }

  before do
    assign(:tombstone, tombstone)
    assign(:metadata, metadata)
    allow(view).to receive(:build_citation).with(metadata).and_return "Doe, Jane. A Title. #{doi}"
    render
  end

  it 'renders the tombstone page' do
    expect(rendered).to have_css("h3.unavailable-doi-heading", text: "Item not available: A Title")
    expect(rendered).to include("This item is no longer available due to test")
    expect(rendered).to include("10.1234/abcd-efgh")
    expect(rendered).to include("Doe, Jane. A Title.")
  end

end