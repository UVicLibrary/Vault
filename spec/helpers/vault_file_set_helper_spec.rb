RSpec.describe VaultFileSetHelper do

  describe '#media_display_partial' do
    subject { helper.media_display_partial(file_set) }

    let(:file_set) { SolrDocument.new(mime_type_ssi: mime_type) }

    context "with an image" do
      let(:mime_type) { 'image/tiff' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/image' }
    end

    context "with a video" do
      let(:mime_type) { 'video/webm' }
      before { allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account) }

      context 'when in Vault' do
        let(:account) { Account.new(name: "vault") }

        it { is_expected.to eq 'hyrax/file_sets/media_display/vault/video' }
      end

      context 'when not in Vault' do
        let(:account) { Account.new(name: "iaff") }

        it { is_expected.to eq 'hyrax/file_sets/media_display/video' }
      end
    end

    context "with an audio" do
      let(:mime_type) { 'audio/wav' }
      before { allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account) }

      context 'when in Vault' do
        let(:account) { Account.new(name: "vault") }

        it { is_expected.to eq 'hyrax/file_sets/media_display/vault/audio' }
      end

      context 'when not in Vault' do
        let(:account) { Account.new(name: "iaff") }

        it { is_expected.to eq 'hyrax/file_sets/media_display/audio' }
      end
    end

    context "with an m4a file" do
      let(:mime_type) { 'video/m4a' }

      before do
        allow(file_set).to receive(:filename).and_return("File.m4a")
        allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(Account.new(name: "vault"))
      end

      it { is_expected.to eq 'hyrax/file_sets/media_display/vault/audio' }
    end

    context "with a pdf" do
      let(:mime_type) { 'application/pdf' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/pdf' }
    end

    context "with a word document" do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/office_document' }
    end

    context "with anything else" do
      let(:mime_type) { 'application/binary' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/default' }
    end
  end

  context 'when in Vault' do
    let(:account) { Account.new(name: "vault") }
    before { allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account) }

    let(:ability)  { double(Ability) }


    describe '#display_media_download_link?' do
      let(:parent_work) { GenericWork.new(downloadable: true) }
      let(:file_set) { FileSet.new }
      subject { helper.display_media_download_link?(file_set: file_set) }

      before do
        allow(controller).to receive(:current_ability).and_return(ability)
        allow(ability).to receive(:can?).with(:edit, "foo").and_return(false)
        allow(file_set).to receive(:parent).and_return(parent_work)
        allow(file_set).to receive(:id).and_return("foo")
      end

      context 'when parent is downloadable' do
        it { is_expected.to eq true }
      end

      context 'when parent is not downloadable' do
        before do
          parent_work.downloadable = false
        end

        context 'and user can edit' do
          before do
            allow(ability).to receive(:can?).with(:edit, "foo").and_return(true)
          end

          it { is_expected.to eq true }
        end

        context 'and user cannot edit' do
          it { is_expected.to eq false }
        end
      end
    end

    let(:file_set) { FileSet.new(id: "foo") }
    let(:presenter) { VaultFileSetPresenter.new(file_set, "admin") }
    let(:work) { double(GenericWork) }
    let(:parent) { VaultWorkShowPresenter.new(work, "admin") }

    describe '#display_pdf_download_link?' do
      subject { helper.display_pdf_download_link?(presenter) }

      before do
        allow(presenter).to receive(:parent).and_return(parent)
        allow(parent).to receive(:member_presenters).and_return([presenter])
        allow(controller).to receive(:current_ability).and_return(ability)
        allow(ability).to receive(:can?).with(:edit, "foo").and_return(true)
      end

      context 'when work has a pdf file set' do
        before { allow(presenter).to receive(:pdf?).and_return true }

        it { is_expected.to eq true }
      end

      context "when work doesn't have a pdf file set" do
        before { allow(presenter).to receive(:pdf?).and_return false }

        it { is_expected.to eq false }
      end
    end

    describe '#pdf_file_set' do
      subject { helper.pdf_file_set(parent) }

      before do
        allow(presenter).to receive(:parent).and_return(parent)
        allow(parent).to receive(:member_presenters).and_return([presenter])
      end

      context 'with a pdf member presenter' do
        before { allow(presenter).to receive(:pdf?).and_return true }

        it { is_expected.to eq presenter }
      end

      context 'without a pdf member presenter' do
        before { allow(presenter).to receive(:pdf?).and_return false }

        it { is_expected.to be_nil }
      end
    end

    describe '#pdf_link_text' do

      before do
        allow(presenter).to receive(:parent).and_return(parent)
        allow(parent).to receive(:member_presenters).and_return([presenter])
        allow(presenter).to receive(:pdf?).and_return true
      end

      subject { helper.pdf_link_text(presenter) }

      context 'with a transcript' do
        before { allow(presenter).to receive(:title).and_return(["Transcript"]) }
        it { is_expected.to eq("Download PDF transcription") }
      end

      context "without a transcript" do
        before { allow(presenter).to receive(:title).and_return(["Summary"]) }
        it { is_expected.to eq("Download PDF") }
      end
    end
  end

  context 'when not in Vault' do
    let(:account) { Account.new(name: "other") }
    before { allow_any_instance_of(HykuHelper).to receive(:current_account).and_return(account) }

    describe '#display_media_download_link?' do
      let(:ability)  { double(Ability) }
      let(:file_set) { FactoryBot.create(:file_set) }

      before { allow(controller).to receive(:current_ability).and_return(ability) }

      it 'does not allow download when permissions restrict it' do
        allow(ability).to receive(:can?).with(:download, file_set).and_return(false)

        expect(helper.display_media_download_link?(file_set: file_set)).to eq false
      end

      it 'allows download when permissions allow it ' do
        allow(ability).to receive(:can?).with(:download, file_set).and_return(true)

        expect(helper.display_media_download_link?(file_set: file_set)).to eq true
      end
    end

    describe '#display_pdf_download_link?' do
      subject { helper.display_pdf_download_link?(double(Hyrax::FileSetPresenter)) }
      it { is_expected.to eq false }
    end
  end
end
