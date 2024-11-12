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

    context 'with a FileSetPresenter' do
      let(:ability) { Ability.new(user) }
      let(:file_set) { FactoryBot.create(:file_set, :with_original_file, user: user) }
      let(:presenter) { Hyrax::FileSetPresenter.new(solr_document, ability) }
      let(:solr_document) { SolrDocument.new(file_set.to_solr) }
      let(:user) { FactoryBot.create(:user) }

      it 'resolves permissions based on the solr document' do
        expect(helper.display_media_download_link?(file_set: presenter))
            .to eq true
      end

      describe '#iiif_image_path' do
        subject { helper.iiif_image_path(presenter, "900,") }

        context 'with a Hyrax file set' do
          it 'returns a path for the latest version' do
            expect(subject).to include('fcr:versions%2Fversion1')
          end
        end

        context 'with a Vault file set' do
          let(:presenter) { VaultFileSetPresenter.new(solr_document, ability) }
          before { allow(presenter).to receive(:current_file_version).and_return("foo/fcr:versions/version2") }

          it 'returns a path for the latest version' do
            expect(subject).to eq "/images/foo%2Ffcr:versions%2Fversion2/full/900,/0/default.jpg"
          end
        end

      end
    end
  end

  describe '#display_pdf_download_link?' do
    let(:ability) { Ability.new(user) }
    let(:file_set) { FactoryBot.create(:file_with_work, user: user) }
    let(:solr_document) { SolrDocument.new(file_set.to_solr) }
    let(:user) { FactoryBot.create(:user) }
    let(:presenter) { VaultFileSetPresenter.new(solr_document, ability) }
    subject { helper.display_pdf_download_link?(presenter) }

    before do
      allow(presenter.parent).to receive(:member_presenters).and_return([presenter])
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'with Vault work and file set presenters' do

      context 'when on a work show page' do
        before { allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" }) }

        context 'when work has a pdf file set' do
          before { allow(presenter).to receive(:pdf?).and_return true }

          it { is_expected.to eq true }
        end

        context "when work doesn't have a pdf file set" do
          before { allow(presenter).to receive(:pdf?).and_return false }

          it { is_expected.to eq false }
        end
      end

      context 'when not on a work show page' do
        before { allow(helper).to receive(:params).and_return({ controller: "hyrax/file_sets" }) }
        it { is_expected.to eq false }
      end
    end

    context 'with Hyrax work and file set presenters' do

      context 'when on a work show page' do
        before { allow(helper).to receive(:params).and_return({ controller: "hyrax/generic_works" }) }

        context 'when work has a pdf file set' do
          before { allow(presenter).to receive(:pdf?).and_return true }

          it { is_expected.to eq true }
        end

        context "when work doesn't have a pdf file set" do
          before { allow(presenter).to receive(:pdf?).and_return false }

          it { is_expected.to eq false }
        end
      end

      context 'when not on a work show page' do
        before { allow(helper).to receive(:params).and_return({ controller: "hyrax/file_sets" }) }
        it { is_expected.to eq false }
      end
    end
  end

end

