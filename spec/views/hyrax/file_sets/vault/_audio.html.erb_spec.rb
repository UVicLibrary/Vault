require 'hyrax/file_set_helper'

RSpec.describe 'hyrax/file_sets/media_display/vault/_audio.html.erb', type: :view do
  let(:file_set) { Hyrax::FileSetPresenter.new(SolrDocument.new(mime_type_ssi: "audio/mp3", id: 'foo'), nil) }
  let(:config) { double }
  let(:link) { true }
  let(:work_presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new, nil) }
  subject { render 'hyrax/file_sets/media_display/vault/audio', file_set: file_set }

  before do
    allow(view).to receive(:can?).with(:edit, file_set.id).and_return true
    allow(view).to receive(:allow_downloads?).with(file_set).and_return true
    allow(Hyrax.config).to receive(:display_media_download_link?).and_return(link)
    allow(view).to receive(:work_show_page?).and_return(true)
    allow(file_set).to receive(:parent).and_return(work_presenter)
  end

  context 'when parent work has more than one audio file' do

    let(:other_file_set) { SolrDocument.new(mime_type_ssi: "audio/mp3") }
    let(:presenters) { [file_set, Hyrax::FileSetPresenter.new(other_file_set, nil)] }

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
    end

    it "draws the view with the link" do
      expect(subject).to have_selector("audio")
      expect(subject).to have_css('a', text: 'Download audio')
    end

    it "includes google analytics data in the download link" do
      expect(subject).to have_css('a#file_download')
      expect(subject).to have_selector("a[data-label=\"#{file_set.id}\"]")
    end

    context "and downloads not allowed" do
      before do
        allow(view).to receive(:can?).with(:edit, file_set.id).and_return false
        allow(view).to receive(:allow_downloads?).with(file_set).and_return false
      end

      it "draws the view without the link" do
        expect(subject).to have_selector("audio")
        expect(subject).not_to have_css('a', text: 'Download audio')
      end
    end

    context "and does not a transcript file" do
      it "has no download transcript link" do
        expect(subject).not_to have_css('a', text: 'Download transcript (PDF)')
      end
    end

    context "and has a transcript file" do
      let(:pdf) { Hyrax::FileSetPresenter.new(SolrDocument.new(mime_type_ssi: "application/pdf", id: 'foo2'), nil) }
      before do
        allow(work_presenter).to receive(:member_presenters).and_return([file_set, pdf])
      end

      it "displays a download transcript link" do
        expect(subject).to have_css('a', text: 'Download transcript (PDF)')
      end
    end

  end
end
