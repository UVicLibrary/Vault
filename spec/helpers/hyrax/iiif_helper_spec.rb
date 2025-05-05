# frozen_string_literal: true
RSpec.describe Hyrax::IiifHelper, type: :helper do
  let(:solr_document) { SolrDocument.new }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }
  let(:uv_partial_path) { 'hyrax/base/iiif_viewers/universal_viewer' }
  let(:ability) { double(Ability) }

  before { allow(controller).to receive(:current_ability).and_return(ability) }

  describe '#iiif_viewer_display' do
    before do
      allow(helper).to receive(:iiif_viewer_display_partial).with(presenter)
                                                            .and_return(uv_partial_path)
    end

    it "renders a partial" do
      expect(helper).to receive(:render)
        .with(uv_partial_path, presenter: presenter)
      helper.iiif_viewer_display(presenter)
    end

    it "takes options" do
      expect(helper).to receive(:render)
        .with(uv_partial_path, presenter: presenter, transcript_id: '123')
      helper.iiif_viewer_display(presenter, transcript_id: '123')
    end
  end

  describe '#iiif_viewer_display_partial' do
    subject { helper.iiif_viewer_display_partial(presenter) }

    it 'defaults to universal viewer' do
      expect(subject).to eq uv_partial_path
    end

    context "with #iiif_viewer override" do
      let(:iiif_viewer) { :mirador }

      before do
        allow(presenter).to receive(:iiif_viewer).and_return(iiif_viewer)
      end

      it { is_expected.to eq 'hyrax/base/iiif_viewers/mirador' }
    end
  end

  context 'when in Vault' do
    before do
      allow(controller.request).to receive(:base_url).and_return("http://vault.host")
      allow(presenter).to receive(:id).and_return "foo"
      allow(helper).to receive(:can?).with(:edit, "foo").and_return(false)
    end

    context "when work is downloadable" do
      let(:presenter) { VaultWorkShowPresenter.new(solr_document, ability) }

      before { allow(helper).to receive(:can?).with(:download, "foo").and_return(true) }

      describe '#universal_viewer_base_url' do
        it 'returns the path for uv.html' do
          expect(helper.universal_viewer_base_url(presenter)).to eq "http://vault.host/uv/uv.html"
        end
      end

      describe 'universal_viewer_config_url' do
        it 'returns the path for regular uv-config' do
          expect(helper.universal_viewer_config_url(presenter)).to eq "http://vault.host/uv/uv-config.json"
        end
      end
    end

    context "when work is not downloadable" do
      let(:presenter) { VaultWorkShowPresenter.new(solr_document, ability) }

      before { allow(helper).to receive(:can?).with(:download, "foo").and_return(false) }

      describe '#universal_viewer_base_url' do
        it 'returns the path for uv.html with no download icon' do
          expect(helper.universal_viewer_base_url(presenter)).to eq "http://vault.host/uv/uv-no-download.html"
        end
      end

      describe 'universal_viewer_config_url' do
        it 'returns the path for regular uv-config' do
          expect(helper.universal_viewer_config_url(presenter)).to eq "http://vault.host/uv/uv-config-no-download.json"
        end
      end
    end
  end

  context 'when not in Vault' do
    let(:request) { ActionController::TestRequest.new(base_url: "http://test.host") }

    describe '#universal_viewer_base_url' do
      it 'returns the path for uv.html' do
        expect(helper.universal_viewer_base_url(presenter)).to eq "http://test.host/uv/uv.html"
      end
    end

    describe 'universal_viewer_config_url' do
      it 'returns the path for regular uv-config' do
        expect(helper.universal_viewer_config_url(presenter)).to eq "http://test.host/uv/uv-config.json"
      end
    end
  end
end
