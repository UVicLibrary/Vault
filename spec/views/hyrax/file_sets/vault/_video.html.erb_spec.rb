require 'av_transcripts_helper'

RSpec.describe 'hyrax/file_sets/media_display/vault/_video.html.erb', type: :view do
  let(:file_set) { Hyrax::FileSetPresenter.new(SolrDocument.new(mime_type_ssi: "video/mp4", id: 'foo'), nil) }
  let(:config) { double }
  let(:link) { true }
  let(:work_presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(full_text_tsi: "Some text"), nil) }
  let(:page) { Capybara::Node::Simple.new(rendered) }
  subject { render 'hyrax/file_sets/media_display/vault/video', file_set: file_set }

  before do
    allow(view).to receive(:can?).with(:edit, file_set.id).and_return true
    allow(view).to receive(:allow_downloads?).with(file_set).and_return true
    allow(Hyrax.config).to receive(:display_media_download_link?).and_return(link)
    allow(view).to receive(:work_show_page?).and_return(true)
    allow(file_set).to receive(:parent).and_return(work_presenter)
  end

  context 'when parent work has more than one video file' do

    let(:other_file_set) { SolrDocument.new(mime_type_ssi: "video/mp4") }
    let(:presenters) { [file_set, Hyrax::FileSetPresenter.new(other_file_set, nil)] }

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
      allow(work_presenter).to receive(:member_presenters).and_return([file_set])
    end

    context "when there is no transcript" do
      before do
        allow(view).to receive(:has_vtt?).with(file_set).and_return false
        allow(view).to receive(:parent_has_transcript?).with(file_set).and_return false
      end

      it "has no download transcript link" do
        expect(subject).not_to have_css('a', text: 'Download transcript (PDF)')
      end
    end

    context 'when file set has vtt transcript' do
      before do
        allow(view).to receive(:has_vtt?).with(file_set).and_return true
        allow(view).to receive(:parent_has_transcript?).with(file_set).and_return false
      end

      it "draws the view with the vtt transcript" do
        expect(subject).to have_selector("video", visible: false)
        expect(subject).to have_selector("track", visible: false)
        expect(page.find('track', visible: false)['src']).to have_content "/able_player/transcripts/foo.vtt"
      end
    end

    context 'when parent has transcript' do
      let(:pdf) { Hyrax::FileSetPresenter.new(SolrDocument.new(mime_type_ssi: "application/pdf", id: 'foo2'), nil) }

      before do
        allow(view).to receive(:has_vtt?).with(file_set).and_return false
        allow(view).to receive(:parent_has_transcript?).with(file_set).and_return true
        allow(work_presenter).to receive(:member_presenters).and_return([file_set, pdf])
      end

      it 'draws a dummy track element and div#transcript-text' do
        expect(subject).to have_selector("video", visible: false)
        expect(subject).to have_selector("track", visible: false)
        expect(page.find('track', visible: false)['src']).to have_content "/able_player/transcripts/blank.vtt"
        expect(page).to have_css('#transcript-text', visible: false)
        expect(page.find('#transcript-text', visible: false)).to have_content "Some text"
      end

      it "displays a download transcript link" do
        expect(subject).to have_css('a', text: 'Download transcript (PDF)')
      end

      it "includes google analytics data" do
        expect(subject).to have_selector("a[data-label=\"#{file_set.id}\"]")
      end

      context "when downloads are not allowed" do
        before do
          allow(view).to receive(:can?).with(:edit, file_set.id).and_return false
          allow(view).to receive(:allow_downloads?).with(file_set).and_return false
        end

        it "draws the view without the link" do
          expect(subject).to have_selector("video", visible: false)
          expect(subject).not_to have_css('a', text: 'Download video')
        end
      end
    end

  end
end
