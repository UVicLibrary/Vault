# frozen_string_literal: true
RSpec.describe Hyrax::DownloadsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:user) { create(:user) }
    let(:file_set) do
      create(:file_with_work, user: user, content: File.open(fixture_path + '/image.png'))
    end

    it 'raises an error if the object does not exist' do
      expect do
        get :show, params: { id: '8675309' }
      end.to raise_error Blacklight::Exceptions::InvalidSolrID
    end

    context "when user doesn't have access" do
      let(:another_user) { create(:user) }

      before do
        sign_in another_user
      end

      it 'returns :unauthorized status with image content' do
        get :show, params: { id: file_set.to_param }
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq 'image/png'
      end

      context "and requests a thumbnail" do
        let(:file) { File.open(fixture_path + '/world.png', 'rb') }
        let(:content) { file.read }

        before do
          allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
        end

        it 'skips authorization and shows thumbnail' do
          expect(controller).not_to receive(:authorize!).with(:download, file_set.id)
          expect(controller).not_to receive(:authorize!).with(:show, file_set.id)
          get :show, params: { id: file_set, file: "thumbnail" }
          expect(response).to be_successful
          expect(response.body).to eq content
          expect(response.headers['Content-Length']).to eq "4218"
          expect(response.headers['Accept-Ranges']).to eq "bytes"
        end
      end
    end

    context "when user isn't logged in" do
      context "and the unauthorized image exists" do
        before do
          allow(File).to receive(:exist?).and_return(true)
        end

        it 'returns :unauthorized status with image content' do
          get :show, params: { id: file_set.to_param }
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to eq 'image/png'
        end
      end

      it 'authorizes the resource using only the id' do
        expect(controller).to receive(:authorize!).with(:download, file_set.id)
        get :show, params: { id: file_set.to_param }
      end
    end

    context "when the user has access" do
      before { sign_in user }

      it 'sends the original file' do
        get :show, params: { id: file_set }
        expect(response.body).to eq file_set.original_file.content
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:file) { File.open(fixture_path + '/world.png', 'rb') }
          let(:content) { file.read }

          before do
            allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
          end

          it 'sends requested file content' do
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to be_successful
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq "4218"
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end

          it 'retrieves the thumbnail without contacting Fedora' do
            expect(ActiveFedora::Base).not_to receive(:find).with(file_set.id)
            get :show, params: { id: file_set, file: 'thumbnail' }
          end

          it 'sends 304 response when client has valid cached data' do
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to have_http_status :success
            request.env['HTTP_IF_MODIFIED_SINCE'] = response.headers['Last-Modified']
            request.env['HTTP_IF_NONE_MATCH'] = response.headers['ETag']
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to have_http_status :not_modified
          end

          context "stream" do
            it "head request" do
              request.env["HTTP_RANGE"] = 'bytes=0-15'
              head :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers['Content-Length']).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with 'image/png'
            end

            it "sends the whole thing" do
              request.env["HTTP_RANGE"] = 'bytes=0-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 0-4217/4218'
              expect(response.headers["Content-Length"]).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with "image/png"
              expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
              expect(response.body).to eq content
              expect(response.status).to eq 206
            end

            it "sends the whole thing when the range is open ended" do
              request.env["HTTP_RANGE"] = 'bytes=0-'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.body).to eq content
            end

            it "gets a range not starting at the beginning" do
              request.env["HTTP_RANGE"] = 'bytes=4200-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4200-4217/4218'
              expect(response.headers["Content-Length"]).to eq '18'
            end

            it "gets a range not ending at the end" do
              request.env["HTTP_RANGE"] = 'bytes=4-11'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4-11/4218'
              expect(response.headers["Content-Length"]).to eq '8'
            end
          end
        end

        context "that isn't persisted" do
          it "raises an error if the requested file does not exist" do
            expect do
              get :show, params: { id: file_set, file: 'thumbnail' }
            end.to raise_error Hyrax::ObjectNotFoundError
          end
        end
      end

      context "when file is a pdf" do
        let(:file_set) do
          create(:file_with_work, user: user, content: File.open(fixture_path + '/issue_01_combined.pdf'))
        end

        it "prepares the pdf range headers" do
          get :show, params: { id: file_set }
          expect(response.headers['Cache-Control']).to eq "private, no-transform"
          expect(response.headers['Content-Encoding']).to eq "identity"
          expect(response.headers["Accept-Ranges"]).to eq "bytes"
          expect(response.headers["Content-Type"]).to eq "application/pdf"
          expect(response.headers["Content-Disposition"]).to eq "attachment; filename=\"issue_01_combined.pdf\""
          expect(response.headers["Content-Length"]).to eq "4770591"
        end
      end

      it "raises an error if the requested association does not exist" do
        expect do
          get :show, params: { id: file_set, file: 'non-existant' }
        end.to raise_error Hyrax::ObjectNotFoundError
      end
    end

    context "when the user has show access but not download access" do
      let(:file_set) do
        create(:file_with_work, user: user, content: File.open(fixture_path + '/image.png'))
      end
      let(:parent) { create(:public_generic_work) }

      before do
        parent.ordered_members << file_set
        parent.downloadable = false
        parent.save!
      end

      context "and visits a work show page" do
        let(:url) { "http://test.localhost/concern/generic_works/#{parent.id}?locale=en" }

        it "allows access and returns the expected content" do
          expect(controller).to receive(:authorize!).with(:show, file_set.id)
          request.env['HTTP_REFERER'] = url
          get :show, params: { id: file_set.to_param }
          expect(response).to be_successful
          expect(response.body).to eq file_set.original_file.content
        end
      end

      context "and visits a parent file set page" do
        let(:url) { "http://test.localhost/concern/parent/#{parent.id}/file_sets/#{file_set.id}?locale=en" }

        it "allows access and returns the expected content" do
          expect(controller).to receive(:authorize!).with(:show, file_set.id)
          request.env['HTTP_REFERER'] = url
          get :show, params: { id: file_set.to_param }
          expect(response).to be_successful
          expect(response.body).to eq file_set.original_file.content
        end
      end

      context "and visits a file set page" do
        let(:url) { "http://test.localhost/concern/file_sets/#{file_set.id}?locale=en" }

        it "allows access and returns the expected content" do
          expect(controller).to receive(:authorize!).with(:show, file_set.id)
          request.env['HTTP_REFERER'] = url
          get :show, params: { id: file_set.to_param }
          expect(response).to be_successful
          expect(response.body).to eq file_set.original_file.content
        end
      end

      context "and visits a pdf viewer page" do
        let(:url) { "http://test.localhost/pdfjs/full?file=/downloads/#{file_set.id}?locale=en" }

        it "allows access and returns the expected content" do
          expect(controller).to receive(:authorize!).with(:show, file_set.id)
          request.env['HTTP_REFERER'] = url
          get :show, params: { id: file_set.to_param }
          expect(response).to be_successful
          expect(response.body).to eq file_set.original_file.content
        end
      end

      context "and visits the download link directly" do
        it 'returns :unauthorized status with image content' do
          get :show, params: { id: file_set.to_param }
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to eq 'image/png'
        end
      end
    end
  end

  describe "derivative_download_options" do
    before do
      allow(controller).to receive(:default_file).and_return 'world.png'
    end
    subject { controller.send(:derivative_download_options) }

    it { is_expected.to eq(disposition: 'inline', type: 'image/png') }
  end
end
