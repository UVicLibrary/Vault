RSpec.describe 'hyrax/file_sets/media_display/vault/_video_playlist.html.erb', type: :view do
  let(:account) { Account.new(name: "vault") }
  let(:video1) { VaultFileSetPresenter.new(SolrDocument.new(
      mime_type_ssi: "video/mp4", id: 'foo', thumbnail_path: "foo.jpg"), nil) }
  let(:video2) { VaultFileSetPresenter.new(SolrDocument.new(
      mime_type_ssi: "video/mp4", id: 'bar', thumbnail_path: "bar.jpg"), nil)}
  let(:transcript) { VaultFileSetPresenter.new(SolrDocument.new(
      mime_type_ssi: "application/pdf", id: 'pdf', thumbnail_path: "pdf.jpg"), nil)}
  let(:work_presenter) { VaultWorkShowPresenter.new(SolrDocument.new(full_text_tsi: "Some text"), nil) }
  let(:link) { true }
  subject { render 'hyrax/file_sets/media_display/vault/video_playlist',
                   file_set: video1,
                   video_files: [video1, video2],
                   parent: work_presenter }

  before do
    allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account)
    allow(view).to receive(:display_media_download_link?).and_return(link)
    allow(view).to receive(:work_show_page?).and_return(true)
    allow(video1).to receive(:parent).and_return(work_presenter)
    allow(video2).to receive(:parent).and_return(work_presenter)
    allow(work_presenter).to receive(:member_presenters).and_return([video1, video2, transcript])
    allow(view).to receive(:vtt_transcript_for).with(video1).and_return(transcript)
    allow(view).to receive(:transcript_for).with(work_presenter).and_return(transcript)

    # Stubbing VTT transcript
    allow(view).to receive(:has_vtt?).with(video1).and_return true
    allow(view).to receive(:has_vtt?).with(video2).and_return true
    allow(view).to receive(:has_transcript?).with(work_presenter).and_return true
  end

  it "renders li and video tags for every file" do
    expect(subject).to have_css("video")
    expect(subject).to have_css("li", count: 2)
    expect(subject).to have_css("li span.able-source", count: 2)
    expect(subject).to have_css("li span.able-track", count: 2)
    expect(subject).to have_css("li button", count: 2)
    expect(subject).to have_css('a', text: 'Download selected video')
  end

  describe 'render transcript link' do

    context 'with a VTT transcript' do
      it "renders a transcript link" do
        expect(subject).to have_link('Download selected transcript (PDF)', href: '/downloads/pdf')
      end

      it 'does not render the transcript-text div' do
        expect(subject).not_to have_selector("div#transcript-text", visible: false)
      end
    end

    context 'with a work-level PDF transcript' do
      before do
        allow(view).to receive(:has_vtt?).with(video1).and_return false
        allow(view).to receive(:has_vtt?).with(video2).and_return false
        allow(view).to receive(:has_transcript?).with(work_presenter).and_return true
      end

      it "renders a transcript link" do
        expect(subject).to have_link('Download transcript (PDF)', href: '/downloads/pdf')
      end

      it "renders the transcript text in a div" do
        expect(subject).to have_css("div#transcript-text", text: "Some text", visible: false)
      end
    end

    context 'without a transcript' do
      before do
        allow(view).to receive(:has_vtt?).with(video1).and_return false
        allow(view).to receive(:has_vtt?).with(video2).and_return false
        allow(view).to receive(:has_transcript?).with(work_presenter).and_return false
      end

      it "does not render a download transcript link" do
        expect(subject).not_to have_link('Download selected transcript (PDF)', href: '/downloads/pdf')
        expect(subject).not_to have_link('Download transcript (PDF)', href: '/downloads/pdf')
      end

      it 'does not render the transcript-text div' do
        expect(subject).not_to have_selector("div#transcript-text", visible: false)
      end
    end
  end

  context "no download links" do
    let(:link) { false }

    it "draws the view without any download links" do
      expect(subject).to have_css("video")
      expect(subject).to have_css("li", count: 2)
      expect(subject).to have_css("span.able-source", count: 2)
      expect(subject).to have_css("li button", count: 2)
      expect(subject).not_to have_link('Download selected transcript (PDF)', href: '/downloads/pdf')
      expect(subject).not_to have_link('Download transcript (PDF)', href: '/downloads/pdf')
    end
  end

  context "on a file set show page" do
    before { allow(view).to receive(:work_show_page?).and_return false }

    it "draws the view with a download video link but no download transcript links" do
      expect(subject).to have_css("video")
      expect(subject).to have_css("li", count: 2)
      expect(subject).to have_css("span.able-source", count: 2)
      expect(subject).to have_css("li button", count: 2)
      expect(subject).to have_link('Download selected video', href: '/downloads/foo')
      expect(subject).not_to have_link('Download selected transcript (PDF)', href: '/downloads/pdf')
      expect(subject).not_to have_link('Download transcript (PDF)', href: '/downloads/pdf')
    end
  end

end