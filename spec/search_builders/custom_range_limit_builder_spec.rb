# frozen_string_literal: true
RSpec.describe CustomRangeLimitBuilder do
  let(:ability) { double('ability') }
  let(:context) { FakeSearchBuilderScope.new }
  let(:user) { double('user') }
  let(:solr_params) { { fq: [] } }

  subject { described_class.new(context) }

  describe "#default_processor_chain" do
    it "includes advanced search" do
      expect(subject.default_processor_chain).to include(:add_advanced_parse_q_to_solr)
      expect(subject.default_processor_chain).to include(:add_advanced_search_to_solr)
    end
  end

  describe "#models" do
    let(:file_set_params) { { "f" => { "has_model_ssim" => "FileSet" } } }
    before { allow(subject).to receive(:blacklight_params).and_return(file_set_params) }

    context "with file set params" do
      it "adds file sets to the list of models" do
        expect(subject.models).to include(FileSet)
      end
    end

    context "without file set params" do
      let(:file_set_params) { { "f" => { "keyword_tesim" => "keyword" } } }

      it "excludes file sets" do
        expect(subject.models).not_to include(FileSet)
      end
    end
  end

  describe "#filter_models" do
    context "with file set params" do
      let(:solr_params) { { fq: ["{!term f=has_model_ssim}FileSet"] } }

      it "replaces {!terms f=has_model_ssim}FileSet with all models" do
        expect(subject.filter_models(solr_params).first).to include("Work")
        expect(subject.filter_models(solr_params).first).to include("Collection")
        expect(subject.filter_models(solr_params)).not_to include("{!terms f=has_model_ssim}FileSet")
      end
    end

    context "without file set params" do
      let(:file_set_params) { { "f" => { "keyword_tesim" => "keyword" } } }

      it "excludes file sets" do
        expect(subject.filter_models(solr_params).first).to include("Work")
        expect(subject.filter_models(solr_params).first).to include("Collection")
        expect(subject.filter_models(solr_params).first).not_to include("FileSet")
      end
    end
  end

end