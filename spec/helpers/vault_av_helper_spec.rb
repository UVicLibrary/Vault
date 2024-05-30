RSpec.describe VaultAvHelper, type: :helper do
  let(:parent) { VaultWorkShowPresenter.new(SolrDocument.new(full_text_tsi: "Some text"), Ability.new(admin)) }
  let(:child_doc) { SolrDocument.new(mime_type_ssi: "video/mp4", id: "foo", title: ["Video"]) }
  let(:child) { VaultFileSetPresenter.new(child_doc, Ability.new(admin)) }
  let(:transcript) { VaultFileSetPresenter.new(SolrDocument.new(
      mime_type_ssi: "application/pdf", id: 'pdf', thumbnail_path: "pdf.jpg", title: ["Transcript"]), nil)}
  let(:admin) { create(:admin) }

  describe "#has_vtt?" do

    before do
      allow(child).to receive(:id).and_return('s1784k724')
    end

    context "when there is no vtt file with the same name" do
      it "returns false" do
        expect(helper.has_vtt?(child)).to be(false)
      end
    end

    context "when there is a .vtt transcript of the same name" do
      before do
        allow(File).to receive(:file?).with(Rails.root.join("public","able_player","transcripts", "#{child.id}.vtt")).and_return(true)
      end
      it "returns true" do
        expect(helper.has_vtt?(child)).to be(true)
      end
    end

  end

  describe "#vtt_path_for" do

    it "returns a path to the .vtt file in the public folder" do
      expect(helper.vtt_path_for(child)).to eq("/able_player/transcripts/#{child.id}.vtt")
    end
  end

  context "when file set has a parent" do

    describe "#has_transcript?(file_set)" do

      context "when parent does not have a transcript" do
        it "returns false" do
          expect(helper.has_transcript?(parent)).to be(false)
        end
      end

      context "when parent has a transcript" do

        before do
          allow(transcript).to receive(:title).and_return(["transcript"])
          allow(parent).to receive(:member_presenters).and_return([child, transcript])
          allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" })
        end

        it "returns true" do
          expect(helper.has_transcript?(parent)).to be(true)
        end
      end

    end

    describe "#transcript_for" do

      context "when work has a pdf file set" do

        before do
          allow(transcript).to receive(:title).and_return(["transcript"])
          allow(parent).to receive(:member_presenters).and_return([child, transcript])
          allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" })
        end

        it "returns the transcript file for the file set's parent" do
          expect(helper.transcript_for(parent)).to eq(transcript)
        end
      end

    end

    describe "#render_track_tag" do
      subject { helper.render_track_tag(child) }

      before do
        allow(child).to receive(:parent).and_return(parent)
        allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" })
        allow(transcript).to receive(:title).and_return(["transcript"])
      end

      context 'when there is a vtt transcript' do
        before do
          allow(File).to receive(:file?).with(Rails.root.join("public","able_player","transcripts", "#{child.id}.vtt")).and_return(true)
        end

        it { is_expected.to eq "<track kind='captions' src='/able_player/transcripts/foo.vtt' srclang='en' label='English'>" }
      end

      context 'when there is a PDF transcript' do

        before do
          allow(parent).to receive(:member_presenters).and_return([child, transcript])
        end

        it { is_expected.to eq "<track kind='captions' src='/able_player/transcripts/blank.vtt' srclang='en' label='English'>" }
      end

      context 'when there is no transcript at all' do

        before do
          allow(parent).to receive(:member_presenters).and_return([child])
        end

        it { is_expected.to eq "" }
      end
    end

    describe "#render_multi_track_tag" do
      subject { helper.render_multi_track_tag(child) }

      before do
        allow(child).to receive(:parent).and_return(parent)
        allow(parent).to receive(:member_presenters).and_return([child, transcript])
      end

      context 'when there is a vtt transcript' do
        before { allow(File).to receive(:file?).with(Rails.root.join("public","able_player","transcripts", "#{child.id}.vtt")).and_return(true) }

        it { is_expected.to eq '<span class="able-track" data-kind="captions" data-src="/able_player/transcripts/foo.vtt" data-srclang="en" data-label="English"></span>' }
      end

      context 'when there is a PDF transcript' do
        # Stub the method since it needs a lot of setup and is already covered by a test above
        before do
          allow(transcript).to receive(:title).and_return(["transcript"])
          allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" })
        end

        it { is_expected.to eq '<span class="able-track" data-kind="captions" data-src="/able_player/transcripts/blank.vtt" data-srclang="en" data-label="English"></span>' }
      end

      context 'when there is no transcript at all' do
        # Stub the method since it needs a lot of setup and is already covered by a test above
        before { allow(parent).to receive(:member_presenters).and_return([child]) }

        it { is_expected.to eq "" }
      end
    end
  end
end