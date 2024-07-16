RSpec.describe 'hyrax/file_sets/media_display/vault/_video.html.erb', type: :view do
  let(:account) { Account.new(name: "vault") }
  let(:file_set) { VaultFileSetPresenter.new(SolrDocument.new(mime_type_ssi: "video/mp4", id: 'foo'), nil) }
  let(:transcript) { VaultFileSetPresenter.new(SolrDocument.new(
      mime_type_ssi: "application/pdf", id: 'pdf', thumbnail_path: "pdf.jpg"), nil)}
  let(:config) { double }
  let(:link) { true }
  let(:work_presenter) { VaultWorkShowPresenter.new(SolrDocument.new(full_text_tsi: "Some text"), nil) }
  subject { render 'hyrax/file_sets/media_display/vault/video', file_set: file_set, parent: work_presenter }


  before do
    allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account)
    allow(view).to receive(:display_media_download_link?).and_return(link)
    allow(view).to receive(:work_show_page?).and_return(true)
    allow(file_set).to receive(:parent).and_return(work_presenter)
  end

  context 'when parent work has more than one video file' do
    let(:other_file_set) { SolrDocument.new(mime_type_ssi: "video/mp4") }
    let(:presenters) { [file_set, VaultFileSetPresenter.new(other_file_set, nil)] }

    before do
      allow(work_presenter).to receive(:member_presenters).and_return(presenters)
      stub_template "hyrax/file_sets/media_display/vault/_video_playlist" => "<div>video playlist</div>"
    end

    it "renders video_playlist" do
      expect(subject).to render_template('hyrax/file_sets/media_display/vault/_video_playlist')
    end
  end

  context 'when parent has only one video file' do

    before do
      without_partial_double_verification do
        allow(work_presenter).to receive(:member_presenters).and_return([file_set])
        allow(view).to receive(:has_vtt?).with(file_set).and_return false
        allow(view).to receive(:has_transcript?).with(work_presenter).and_return false
        allow(view).to receive(:display_pdf_download_link?).with(file_set).and_return true
        allow(view).to receive(:display_pdf_download_link?).with(work_presenter).and_return true
        allow(view).to receive(:transcript_for).with(work_presenter).and_return(transcript)
      end
    end

    # Only doing a minimal example here since more complicated logic is covered in vault_av_helper_spec
    it 'renders the correct elements and does not render video_playlist' do
      expect(subject).to have_selector("video[data-able-player]", visible: false)
      expect(subject).not_to render_template('hyrax/file_sets/media_display/vault/_video_playlist')
    end

    it "includes google analytics data in the download link" do
      expect(subject).to have_css('a#file_download')
      expect(subject).to have_selector("a[data-label=\"#{file_set.id}\"]")
    end

    context 'with a VTT transcript' do
      before do
        without_partial_double_verification do
          allow(view).to receive(:has_vtt?).with(file_set).and_return true
          allow(view).to receive(:vtt_transcript_for).with(file_set).and_return transcript
        end
      end

      it "renders a download transcript link and a track tag" do
        expect(subject).to have_selector("video[data-able-player]", visible: false)
        expect(subject).to have_css("track", visible: false)
      end

      it 'does not render the transcript-text div' do
        expect(subject).not_to have_selector("div#transcript-text", visible: false)
      end
    end

    context "with a PDF transcript" do

      before do
        without_partial_double_verification do
          allow(view).to receive(:has_transcript?).with(work_presenter).and_return true
          allow(view).to receive(:transcript_for).with(work_presenter).and_return(double(id: "pdf"))
        end
      end

      it "draws the PDF transcript download link" do
        expect(subject).to have_selector("video", visible: false)
        expect(subject).to have_selector("track", visible: false)
        expect(subject).to have_css('a', text: 'Download transcript (PDF)')
      end

      it "renders the transcript text in a div" do
        expect(subject).to have_css("div#transcript-text", text: "Some text", visible: false)
      end
    end

    context 'no PDF transcript' do
      before do
        without_partial_double_verification do
          allow(view).to receive(:has_vtt?).with(file_set).and_return false
          # allow(view).to receive(:display_pdf_download_link?).with(work_presenter).and_return false
          allow(view).to receive(:work_show_page?).and_return true
        end
      end

      it "draws the view without PDF transcript download link" do
        expect(subject).to have_selector("video", visible: false)
        expect(subject).not_to have_selector("track", visible: false)
        expect(subject).not_to have_css('a', text: 'Download transcript (PDF)')
      end

      it 'does not render the transcript-text div' do
        expect(subject).not_to have_selector("div#transcript-text", visible: false)
      end
    end

    context "no download links" do
      let(:link) { false }

      it "draws the view without the link" do
        expect(subject).to have_selector("video", visible: false)
        expect(subject).not_to have_css('a', text: 'Download video')
      end
    end

  end
end
