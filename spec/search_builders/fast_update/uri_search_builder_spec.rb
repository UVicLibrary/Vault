# frozen_string_literal: true
RSpec.describe FastUpdate::UriSearchBuilder do

  let(:builder) { described_class.new(User.new) }

  describe "#default_processor_chain" do

    subject { described_class.default_processor_chain }

    let(:blacklight_filters) do
      [
          :default_solr_parameters,
          :add_query_to_solr,
          :add_facet_fq_to_solr,
          :add_facetting_to_solr,
          :add_solr_fields_to_query,
          :add_paging_to_solr,
          :add_sorting_to_solr,
          :add_group_config_to_solr,
          :add_facet_paging_to_solr,
          :add_access_controls_to_solr_params,
          :filter_models
      ]
    end

    it { is_expected.to eq blacklight_filters + [:filter_by_uri] }
  end

  describe "#uri_filter_query" do
    let(:uri) { "http://id.worldcat.org/fast/549011" }
    let(:service) { FastUpdate::LinkedDataSearchService.new("", uri) }
    let(:expected_query) { "creator_tesim:\"http://id.worldcat.org/fast/549011\" OR contributor_tesim:\"http://id.worldcat.org/fast/549011\"" }

    before do
      allow(FastUpdate::LinkedDataSearchService).to receive(:new).with('', uri).and_return(service)
      allow(service).to receive(:controlled_properties).and_return([:creator, :contributor])
    end

    it "returns a joined query based on a work's controlled properties" do
      expect(builder.uri_filter_query(uri)).to eq(expected_query)
    end
  end

  describe "#add_sorting_to_solr" do
    subject { builder.add_sorting_to_solr({}) }

    it "sorts alphabetically by title if title sort field is available" do
      expect(subject).to eq("title_sort_ssi asc")
    end
  end
end
