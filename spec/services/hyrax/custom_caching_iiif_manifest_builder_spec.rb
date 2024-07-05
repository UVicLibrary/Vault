# frozen_string_literal: true

RSpec.describe Hyrax::CustomCachingIiifManifestBuilder, :clean_repo do
  let(:id) { "123" }
  let(:manifest_url) { File.join("https://samvera.org", "show", id) }
  let(:etag) { 'my_etag' }
  let(:work_presenter) { double("Work Presenter") }
  let(:file_set_presenter) { double("File Set Presenter", id: "456") }

  let(:presenter) do
    double(
        'Presenter',
        id: id,
        version: etag,
        work_presenters: [work_presenter],
        manifest_url: manifest_url,
        description: ["A Treatise on Coding in Samvera"],
        file_set_presenters: [file_set_presenter]
    )
  end

  subject(:builder) { described_class.new }

  before do
    allow(presenter).to receive(:member_presenters).and_return [file_set_presenter]
    allow(presenter).to receive(:timestamp).and_return "2024-07-05"
  end

  it 'hits the cache' do
    expect(Rails.cache).to receive(:fetch).and_yield
    builder.manifest_for(presenter: presenter)
  end

  it 'calls the custom manifest builder service' do
    Rails.cache.delete(builder.send(:manifest_cache_key, presenter: presenter))
    expect(Hyrax::CustomManifestBuilderService).to receive(:manifest_for).with(presenter: presenter)
    builder.manifest_for(presenter: presenter)
  end

  it 'uses the timestamp in #manifest_cache_key' do
    expect(builder.send(:manifest_cache_key, presenter: presenter)).to match /2024-07-05/
  end

end