# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe VipsDerivativesService do
  let(:valid_file_set) do
    FileSet.new.tap do |f|
      allow(f).to receive(:mime_type).and_return(FileSet.image_mime_types.first)
    end
  end

  subject { described_class.new(valid_file_set) }

  context 'with an image' do
    let(:source) { Rails.root.join('spec','fixtures','world.png').to_s }

    it 'does not create derivatives' do
      expect(subject.send(:create_image_derivatives, source)).to be_nil
    end

  end

  context 'with a pdf' do

    let(:valid_file_set) do
      FileSet.new.tap do |f|
        allow(f).to receive(:mime_type).and_return(FileSet.pdf_mime_types.first)
        allow(f).to receive(:uri).and_return('http://foo.bar')
      end
    end

    before { allow(valid_file_set).to receive(:id).and_return("foo") }

    describe '#pdf_thumbnail_url' do

      it 'returns the url to the thumbnail' do
        expect(subject.pdf_thumbnail_url).to eq "/pdf_thumbnails/foo-thumb.jpg"
      end

    end

    describe '#create_pdf_derivatives' do

      context 'when libvips is installed' do

        before do
          allow(subject).to receive(:pdf_thumbnail_dir).and_return(Rails.root.join('tmp'))
          allow(Hydra::Derivatives::FullTextExtract).to receive(:create)
        end

        let(:valid_file_set) { create(:file_set, :pdf) }
        let(:source) { Rails.root.join('spec','fixtures','issue_01_combined.pdf').to_s }
        let(:dest_file) { Rails.root.join('tmp','foo-thumb.jpg') }

        it 'creates a pdf thumbnail' do
          subject.send(:create_pdf_derivatives, source)
          expect(dest_file).to exist
        end

        it 'calls the full text extractor' do
          expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
                                                           .with("/home/app/webapp/spec/fixtures/issue_01_combined.pdf",
                                                                 outputs: [
                                                                   { url: valid_file_set.uri,
                                                                     container: "extracted_text" }
                                                                 ])
          subject.send(:create_pdf_derivatives, source)
        end

        # clean up the generated file
        after { FileUtils.rm_f(dest_file) }

      end

    end
  end

  it_behaves_like "a Hyrax::DerivativeService"
end
