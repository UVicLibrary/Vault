RSpec.describe 'hyrax/doi/tombstones/new.html.erb', type: :view do
  let(:tombstone) { Hyrax::DOI::Tombstone.new(doi: "10.1234/abcd-efgh", hyrax_id: "foobar", reason: "test") }

  before do
    assign(:tombstone, tombstone)
    render
  end

  it 'renders the tombstone form' do
    expect(rendered).to have_selector('form[action="/doi/tombstones"][method="post"]')
  end

  it 'renders a dropdown menu with a list of controlled values for the reason' do
    expect(rendered).to have_selector('select[name="tombstone[reason]"]')
    expect(rendered).to have_selector('option[value="rights or privacy restrictions"]')
    expect(rendered).to have_selector('option[value="technical or structural issues"]')
  end

  it 'renders the hidden fields with the correct values' do
    expect(rendered).to have_selector('input[type="hidden"][name="tombstone[doi]"][value="10.1234/abcd-efgh"]', visible: false)
    expect(rendered).to have_selector('input[type="hidden"][name="tombstone[hyrax_id]"][value="foobar"]', visible: false)
  end

end