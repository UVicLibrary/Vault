# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::FileSetFacetedRenderer do

  let(:renderer) { described_class.new(:keyword, [value], options) }
  let(:document) { double }
  let(:options) { { document: document } }
  let(:value) { 'Cortinarius' }

  subject { renderer.search_path(value) }

  it 'adds has_model_ssim to the search path' do
    expect(subject).to include "f%5Bhas_model_ssim%5D%5B%5D=FileSet&f%5Bkeyword_sim%5D%5B%5D=Cortinarius"
  end

end