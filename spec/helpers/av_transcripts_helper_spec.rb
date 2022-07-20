RSpec.describe AvTranscriptsHelper, type: :helper do

  describe "#has_vtt?(file_set)" do

    let(:file_set) { FileSet.new }

    before do
      allow(file_set).to receive(:id).and_return('s1784k724')
    end

    context "when there is no vtt file with the same name" do
      it "returns false" do
        expect(helper.has_vtt?(file_set)).to be(false)
      end
    end

    context "when there is a .vtt transcript of the same name" do
      before do
        allow(File).to receive(:file?).with(Rails.root.join("public","able_player","transcripts", "#{file_set.id}.vtt")).and_return(true)
      end
      it "returns true" do
        expect(helper.has_vtt?(file_set)).to be(true)
      end
    end

  end

  describe "#vtt_path_for(file_set)" do

    let(:file_set) { FileSet.new }

    before do
      allow(file_set).to receive(:id).and_return('s1784k724')
    end

    it "returns a path to the .vtt file in the public folder" do
      expect(helper.vtt_path_for(file_set)).to eq("/able_player/transcripts/#{file_set.id}.vtt")
    end
  end

  describe "#work_show_page?" do

    context "on a file set show page" do
      before do
        allow(helper).to receive(:params).and_return({ controller: "hyrax/file_set" })
      end
      it "returns false" do
        expect(helper.work_show_page?).to be(false)
      end
    end

    context "on a work show page" do
      before do
        allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" })
      end
      it "returns true" do
        expect(helper.work_show_page?).to be(true)
      end
    end
  end

  context "when file set has a parent" do

    let(:work) { create(:work_with_one_file) }
    let(:parent_doc) { SolrDocument.find(work.id) }
    let(:child_doc) { double("Video Document", id: work.file_sets.first.id, title: ["Video"]) }
    let(:child) { Hyrax::FileSetPresenter.new(child_doc,"admin") }

    describe "#parent_has_transcript?(file_set)" do

      context "when parent does not have a transcript" do
        it "returns false" do
          expect(helper.parent_has_transcript?(child)).to be(false)
        end
      end

      context "when parent does have a transcript" do
        before do
          allow(SolrDocument).to receive(:find).with(work.id).and_return(parent_doc)
          allow(parent_doc).to receive(:full_text).and_return("Some transcript text")
          allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" })
        end
        it "returns true" do
          expect(helper.parent_has_transcript?(child)).to be(true)
        end
      end

    end

    describe "#parent_transcript_for(file_set)" do

      context "when work has a pdf file set" do

        let(:transcript) { create(:file_set) }
        let(:transcript_doc) { double("Transcript Document", id: transcript.id, title: ["Transcript"]) }
        let(:transcript_presenter) { Hyrax::FileSetPresenter.new(transcript_doc,"admin") }
        let(:parent_presenter) { child.parent }

        before do
          allow(transcript_doc).to receive(:pdf?).and_return(true)
          allow(child).to receive(:pdf?).and_return(false)
          allow(parent_presenter).to receive(:member_presenters).and_return([child, transcript_presenter])
        end

        it "returns the transcript file for the file set's parent" do
          expect(helper.parent_transcript_for(child)).to eq(transcript_presenter)
        end
      end

    end

  end

end