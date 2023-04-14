# frozen_string_literal: true
RSpec.describe 'fast_update/changes/index.html.erb', type: :view do

  let(:change) { FastUpdate::Change.new }
  let(:changes) { [FastUpdate::Change.new] }

  before do
    assign(:change, change)
    assign(:changes, changes)
    stub_template '_form.html.erb' => 'change form partial'
    stub_template '_changes_table.html.erb' => 'changes table partial'
    stub_template '_search_results.html.erb' => 'search results partial'
    render
  end

  # Expect it to render content
  it 'displays the page' do
    expect(rendered).to have_content 'change form partial'
    expect(rendered).to have_content 'changes table partial'
    expect(rendered).to have_content 'search results partial'
  end
end