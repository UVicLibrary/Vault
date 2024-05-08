# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::FileSetDerivativesService do
  let(:valid_file_set) do
    FileSet.new.tap do |f|
      allow(f).to receive(:mime_type).and_return(FileSet.image_mime_types.first)
    end
  end

  subject { described_class.new(valid_file_set) }

  it_behaves_like "a Hyrax::DerivativeService"

  context 'with a pdf' do

    let(:valid_file_set) do
      FileSet.new.tap do |f|
        allow(f).to receive(:mime_type).and_return(FileSet.pdf_mime_types.first)
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

        before { allow(subject).to receive(:pdf_thumbnail_dir).and_return(Rails.root.join('tmp')) }

        let(:source) { Rails.root.join('spec','fixtures','issue_01_combined.pdf').to_s }
        let(:dest_file) { Rails.root.join('tmp','foo-thumb.jpg') }

        it 'creates a pdf thumbnail' do
          subject.send(:create_pdf_derivatives, source)
          expect(dest_file).to exist
        end

        # clean up the generated file
        after { FileUtils.rm_f(dest_file) }

      end

    end
  end
end
