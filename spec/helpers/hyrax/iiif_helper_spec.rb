RSpec.describe Hyrax::IiifHelper, type: :helper do
  let(:solr_document) { SolrDocument.new }
  let(:request) { double }
  let(:ability) { nil }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability, request) }
  let(:uv_partial_path) { 'hyrax/base/iiif_viewers/universal_viewer' }

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

  context "when work is downloadable" do
    let(:work_object) { GenericWork.new(downloadable: true) }

    before do
      allow(helper).to receive(:class_name).with(presenter).and_return(GenericWork)
      allow(GenericWork).to receive(:find).with(presenter.id).and_return(work_object)
    end

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

  context "when work is not downloadable" do

    let(:work_object) { GenericWork.new(downloadable: false) }

    before do
      allow(helper).to receive(:class_name).with(presenter).and_return(GenericWork)
      allow(GenericWork).to receive(:find).with(presenter.id).and_return(work_object)
      allow(helper).to receive(:can?).with(:edit, presenter.id).and_return(false)
    end

    context 'and in Vault' do
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:base_url).and_return("http://vault.host")
      end

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

      context "when user can edit the work" do
        before do
          allow(helper).to receive(:can?).with(:edit, presenter.id).and_return(true)
        end

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

    end



  end
end
