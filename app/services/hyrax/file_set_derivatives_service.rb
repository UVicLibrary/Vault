module Hyrax
  # Responsible for creating and cleaning up the derivatives of a file_set
  class FileSetDerivativesService
    attr_reader :file_set
    delegate :uri, :mime_type, to: :file_set

    require 'combine_pdf'
    require 'pdftoimage'
    require 'csv'
    require 'fileutils'
    require 'pathname'

    # @param file_set [Hyrax::FileSet] At least for this class, it must have #uri and #mime_type
    def initialize(file_set)
      @file_set = file_set
    end

    def cleanup_derivatives
      derivative_path_factory.derivatives_for_reference(file_set).each do |path|
        FileUtils.rm_f(path)
      end
    end

    def valid?
      supported_mime_types.include?(mime_type)
    end

    def create_derivatives(filename)
      case mime_type
      when *file_set.class.pdf_mime_types             then create_pdf_derivatives(filename)
      when *file_set.class.office_document_mime_types then create_office_document_derivatives(filename)
      when *file_set.class.audio_mime_types           then create_audio_derivatives(filename)
      when *file_set.class.video_mime_types           then create_video_derivatives(filename)
      when *file_set.class.image_mime_types           then create_image_derivatives(filename)
      end
    end

    # The destination_name parameter has to match up with the file parameter
    # passed to the DownloadsController
    def derivative_url(destination_name)
      path = derivative_path_factory.derivative_path_for_reference(file_set, destination_name)
      URI("file://#{path}").to_s
    end

    private

      def supported_mime_types
        file_set.class.pdf_mime_types +
          file_set.class.office_document_mime_types +
          file_set.class.audio_mime_types +
          file_set.class.video_mime_types +
          file_set.class.image_mime_types
      end

      def create_pdf_derivatives(filename)
          # filename is supposed to be the full path to the file
          # but sometimes we get a weird error where it's a path to a directory
          # so we set filename to be the file in the directory instead
          if File.directory?(filename)
            file = Dir["#{filename}/*"].first
            new_filename = (Dir["#{file}"]).to_s
          else
            new_filename = filename
          end

          puts new_filename
          first_page = CombinePDF.load(new_filename).pages[0]
          new_pdf = CombinePDF.new
          new_pdf << first_page
          first_page_path = "/usr/local/rails/vault/working/#{File.basename(new_filename).split(".")[0].gsub("&","_").gsub("'","")}-cover.pdf" # & in a file name causes this to fail
          new_pdf.save first_page_path
          # Resize, create and save a thumbnail in assets directory
          # Find what collection the fileset belongs to and create a folder named after it
          collection = Collection.find(@file_set.parent.member_of_collection_ids.first)
          collection_title = collection.title.first.parameterize.underscore
          # If directory doesn't already exist, create one
          path_prefix = "/usr/local/rails/vault/public/pdf_thumbnails/#{collection_title}"
          unless File.directory?(path_prefix)
            FileUtils.mkdir_p(path_prefix)
          end
          target_path = "#{path_prefix}/#{@file_set.id}-thumb.jpg"
          image = PDFToImage.open(first_page_path).first.resize("50%").save(target_path) # Change to assets folder named by collection
          File.delete(first_page_path)
          extract_full_text(new_filename, uri)
      end

      def create_office_document_derivatives(filename)
        Hydra::Derivatives::DocumentDerivatives.create(filename,
                                                       outputs: [{
                                                         label: :thumbnail, format: 'jpg',
                                                         size: '200x150>',
                                                         url: derivative_url('thumbnail'),
                                                         layer: 0
                                                       }])
        extract_full_text(filename, uri)
      end

      def create_audio_derivatives(filename)
        Hydra::Derivatives::AudioDerivatives.create(filename,
                                                    outputs: [{ label: 'mp3', format: 'mp3', url: derivative_url('mp3') },
                                                              { label: 'ogg', format: 'ogg', url: derivative_url('ogg') }])
      end

      def create_video_derivatives(filename)
        Hydra::Derivatives::VideoDerivatives.create(filename,
                                                    outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') },
                                                              { label: 'webm', format: 'webm', url: derivative_url('webm') },
                                                              { label: 'mp4', format: 'mp4', url: derivative_url('mp4') }])
      end

      def create_image_derivatives(filename)
        # We're asking for layer 0, becauase otherwise pyramidal tiffs flatten all the layers together into the thumbnail
        Hydra::Derivatives::ImageDerivatives.create(filename,
                                                    outputs: [{ label: :thumbnail,
                                                                format: 'jpg',
                                                                size: '200x150>',
                                                                url: derivative_url('thumbnail'),
                                                                layer: 0 }])
      end

      def derivative_path_factory
        Hyrax::DerivativePath
      end

      # Calls the Hydra::Derivates::FulltextExtraction unless the extract_full_text
      # configuration option is set to false
      # @param [String] filename of the object to be used for full text extraction
      # @param [String] uri to the file set (deligated to file_set)
      def extract_full_text(filename, uri)
        return unless Hyrax.config.extract_full_text?
        Hydra::Derivatives::FullTextExtract.create(filename,
                                                   outputs: [{ url: uri, container: "extracted_text" }])
      end
  end
end
