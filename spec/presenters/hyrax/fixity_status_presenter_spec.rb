# frozen_string_literal: true
RSpec.describe Hyrax::FixityStatusPresenter do
  let(:file_set_id) { "xw42n7888" }
  let(:file_set) { FileSet.new(id: file_set_id) }
  let(:presenter) { described_class.new(file_set_id) }

  let(:last_fixity) { "20250207210005" }
  let(:log_path) { File.join(BatchExport::FixityCheckJob::LOG_DIR, "#{last_fixity}.log") }

  before { allow(ActiveFedora::Base).to receive(:find).with(file_set_id).and_return(file_set) }

  describe "#render_file_set_status" do

    describe "no logs recorded" do
      it "returns message" do
        expect(presenter.render_file_set_status).to eq "Fixity checks have not yet been run on this object"
      end
    end

    describe "success" do

      before do
        allow(file_set).to receive(:last_fixity_check).and_return(last_fixity)
        allow(File).to receive(:exist?).with(log_path).and_return true
        allow(File).to receive(:read).with(log_path).and_return ""
      end

      it "creates success message with details" do
        result = presenter.render_file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"badge badge-success\">passed</span>")
        expect(result).to include("on February 07, 2025 at 21:00")
      end
    end

    describe "failure" do

      before do
        allow(file_set).to receive(:last_fixity_check).and_return(last_fixity)
        allow(File).to receive(:exist?).with(log_path).and_return true
        allow(File).to receive(:read).with(log_path).and_return file_set_id
      end

      it "creates failure message with details" do
        result = presenter.render_file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"badge badge-danger\">FAILED</span>")
        expect(result).to include("on February 07, 2025 at 21:00")
      end
    end

    describe "unknown" do

      before { allow(file_set).to receive(:last_fixity_check).and_return(last_fixity) }

      it "creates an unknown status message" do
        result = presenter.render_file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"badge badge-warning\">unknown</span>")
        expect(result).to include("Fixity checks have been run but Hyrax cannot find the status.")
      end

    end
  end
end
