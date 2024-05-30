RSpec.describe 'hyrax/file_sets/media_display/_audio.html.erb', type: :view do
  let(:ability)  { double(Ability) }
  let(:file_set) { stub_model(FileSet, id: id, parent: parent) }
  let(:parent) { double }
  let(:link) { true }
  let(:id) { "foo" }
  subject { render 'hyrax/file_sets/media_display/audio', file_set: file_set }

  before do
    allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account)
    allow(view).to receive(:can?).with(:download, file_set.id).and_return true
    allow(view).to receive(:workflow_restriction?).with(parent).and_return(false)
    allow(view).to receive(:display_media_download_link?).and_return(link)
    stub_template "hyrax/file_sets/media_display/vault/_audio" => "<div>vault audio partial</div>"
  end

  context 'when account is vault' do
    let(:account) { Account.new(name: "vault") }

    it 'renders the vault audio partial' do
      expect(subject).to render_template('hyrax/file_sets/media_display/vault/_audio')
    end
  end

  context 'when account is not vault' do
    let(:account) { Account.new(name: "other") }

    before { render 'hyrax/file_sets/media_display/audio', file_set: file_set }

    it "draws the view with the link" do
      expect(rendered).to have_selector("audio")
      expect(rendered).to have_css('a', text: 'Download audio')
    end

    it "includes google analytics data in the download link" do
      expect(rendered).to have_css('a#file_download')
      expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
    end

    context "no download links" do
      let(:link) { false }

      it "draws the view without the link" do
        expect(rendered).to have_selector("audio")
        expect(rendered).not_to have_css('a', text: 'Download audio')
      end
    end

  end
end
