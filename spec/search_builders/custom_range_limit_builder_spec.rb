# frozen_string_literal: true
RSpec.describe CustomRangeLimitBuilder do
  let(:ability) { double('ability') }
  let(:context) { FakeSearchBuilderScope.new }
  let(:user) { double('user') }

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

end