# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe VipsDerivativesService do
  let(:valid_file_set) do
    FileSet.new.tap do |f|
      allow(f).to receive(:mime_type).and_return(FileSet.image_mime_types.first)
    end
  end
  let(:dest_file) { Hyrax::DerivativePath.derivative_path_for_reference(valid_file_set, 'thumbnail') }

  subject { described_class.new(valid_file_set).create_derivatives(source) }

  context 'with an image' do
    let(:source) { Rails.root.join('spec','fixtures','world.png').to_s }

    it 'creates a thumbnail' do
      subject
      expect(File).to exist(dest_file)
    end

  end

  context 'with a video' do
    let(:valid_file_set) do
      FileSet.new.tap do |f|
        allow(f).to receive(:mime_type).and_return(FileSet.video_mime_types.first)
      end
    end

    let(:source) { Rails.root.join('spec','fixtures','1963-11-14_Space_Movie_512kb.mp4').to_s }

    it 'creates a thumbnail' do
      subject
      expect(File).to exist(dest_file)
    end
  end

  context 'with a pdf' do

    let(:valid_file_set) do
      FileSet.new.tap do |f|
        allow(f).to receive(:mime_type).and_return(FileSet.pdf_mime_types.first)
        allow(f).to receive(:id).and_return('foo')
      end
    end


    before do
      allow(Hydra::Derivatives::FullTextExtract).to receive(:create)
    end

    let(:source) { Rails.root.join('spec','fixtures','issue_01_combined.pdf').to_s }

    it 'creates a pdf thumbnail' do
      subject
      expect(File).to exist(Rails.root.join("public","pdf_thumbnails","foo-thumb.jpg").to_s)
      expect(File).to exist("/home/app/webapp/tmp/derivatives/fo/o-thumbnail.jpeg")
    end

    it 'calls the full text extractor' do
      expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
      subject
    end

    after { FileUtils.rm_f(Rails.root.join("public","pdf_thumbnails","foo-thumb.jpg")) }
  end

  # clean up the generated file
  after { FileUtils.rm_f(Hyrax::DerivativePath.derivative_path_for_reference(valid_file_set, 'thumbnail')) }

  it_behaves_like "a Hyrax::DerivativeService"
end
