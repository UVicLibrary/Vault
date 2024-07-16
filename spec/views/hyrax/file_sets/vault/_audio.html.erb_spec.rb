RSpec.describe 'hyrax/file_sets/media_display/vault/_audio.html.erb', type: :view do
  let(:account) { Account.new(name: "vault") }

  let(:file_set) { VaultFileSetPresenter.new(SolrDocument.new(mime_type_ssi: "audio/mp3", id: 'foo'), nil) }
  let(:transcript) { VaultFileSetPresenter.new(SolrDocument.new(
      mime_type_ssi: "application/pdf", id: 'pdf', thumbnail_path: "pdf.jpg"), nil)}
  let(:config) { double }
  let(:link) { true }
  let(:work_presenter) { VaultWorkShowPresenter.new(SolrDocument.new(full_text_tsi: "Some text"), nil) }
  subject { render 'hyrax/file_sets/media_display/vault/audio', file_set: file_set, parent: work_presenter }

  before do
    allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account)
    allow(view).to receive(:display_media_download_link?).and_return(link)
    allow(view).to receive(:work_show_page?).and_return(true)
    allow(file_set).to receive(:parent).and_return(work_presenter)
  end

  context 'when parent work has more than one audio file' do
    let(:other_file_set) { SolrDocument.new(mime_type_ssi: "audio/mp3") }
    let(:presenters) { [file_set, VaultFileSetPresenter.new(other_file_set, nil)] }

    before do
      allow(work_presenter).to receive(:member_presenters).and_return(presenters)
      stub_template "hyrax/file_sets/media_display/vault/_audio_playlist" => "<div>audio playlist</div>"
    end

    it "renders audio_playlist" do
      expect(subject).to render_template('hyrax/file_sets/media_display/vault/_audio_playlist')
    end
  end

  context 'when parent has only one audio file' do

    before do
      allow(work_presenter).to receive(:member_presenters).and_return([file_set])
      allow(view).to receive(:has_vtt?).with(file_set).and_return false
      allow(view).to receive(:has_transcript?).with(work_presenter).and_return false
      allow(view).to receive(:display_pdf_download_link?).with(work_presenter).and_return true
    end

    # Only doing a minimal example here since more complicated logic is covered in vault_av_helper_spec
    it 'renders the correct elements and does not render audio_playlist' do
      expect(subject).to have_selector("audio[data-able-player]")
      expect(subject).not_to render_template('hyrax/file_sets/media_display/vault/_audio_playlist')
    end

    it "includes google analytics data in the download link" do
      expect(subject).to have_css('a#file_download')
      expect(subject).to have_selector("a[data-label=\"#{file_set.id}\"]")
    end

    context 'with a VTT transcript' do
      before do
        allow(view).to receive(:has_vtt?).with(file_set).and_return true
        allow(view).to receive(:vtt_transcript_for).with(file_set).and_return transcript
      end

      it "renders a download transcript link and a track tag" do
        expect(subject).to have_selector("audio[data-able-player]")
        expect(subject).to have_css("track")
        expect(subject).to have_link('Download selected transcript (PDF)', href: '/downloads/pdf')
      end

      it 'does not render the transcript-text div' do
        expect(subject).not_to have_selector("div#transcript-text", visible: false)
      end
    end

    context "with a work-level PDF transcript" do
      before do
        without_partial_double_verification do
          allow(view).to receive(:work_show_page?).and_return true
          allow(view).to receive(:has_transcript?).with(work_presenter).and_return true
          allow(view).to receive(:transcript_for).with(work_presenter).and_return(transcript)
        end
      end

      it "draws the PDF transcript download link" do
        expect(subject).to have_selector("audio[data-able-player]")
        expect(subject).to have_css('a', text: 'Download transcript (PDF)')
      end

      it "renders the transcript text in a div" do
        expect(subject).to have_css("div#transcript-text", text: "Some text", visible: false)
      end
    end

    context 'no work-level PDF transcript' do
      before do
        without_partial_double_verification do
          allow(view).to receive(:display_pdf_download_link?).with(work_presenter).and_return false
          allow(view).to receive(:work_show_page?).and_return false
        end
      end

      it "draws the view without PDF transcript download link" do
        expect(subject).to have_selector("audio[data-able-player]")
        expect(subject).not_to have_css('a', text: 'Download transcript (PDF)')
      end

      it 'does not render the transcript-text div' do
        expect(subject).not_to have_selector("div#transcript-text", visible: false)
      end
    end

    context "no download links" do
      let(:link) { false }

      it "draws the view without the link" do
        expect(subject).to have_selector("audio")
        expect(subject).not_to have_css('a', text: 'Download audio')
      end
    end
  end

end
