# frozen_string_literal: true

# OVERRIDE class from Hyrax v. 3.4.2
#
# In Hyrax v. 4, the derivatives service becomes a configurable
# (https://github.com/samvera/hyrax/commit/6f6b28fd3e4b7d5572d7a2452f63aa98b9f9726f).
# Once this is available, we should create a new service that inherits
# from Hyrax::FileSetDerivativesService and configure/call it in
# config/initializers/hyrax.rb.
#
module Hyrax
  module FileSetDerivativesServiceDecorator
    extend ActiveSupport::Concern

    # Override to omit generating image thumbnails
    def create_derivatives(filename)
      case mime_type
      when *file_set.class.pdf_mime_types             then create_pdf_derivatives(filename)
      when *file_set.class.office_document_mime_types then create_office_document_derivatives(filename)
      when *file_set.class.audio_mime_types           then create_audio_derivatives(filename)
      when *file_set.class.video_mime_types           then create_video_derivatives(filename)
      # Do not generate image thumbnails because we use IIIF instead
      # when *file_set.class.image_mime_types           then create_image_derivatives(filename)
      end
    end

    # @return [String] The url to the
    def pdf_thumbnail_url
      dir = pdf_thumbnail_dir.to_s.gsub(Rails.root.to_s,'').gsub('/public','')
      "#{dir}/#{@file_set.id}-thumb.jpg"
    end

    private

      # Overriding to not make webm files (which slows down the CreateDerivativesJob SO MUCH)
      def create_video_derivatives(filename)
        Hydra::Derivatives::VideoDerivatives.create(filename,
                                                    outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') },
                                                              { label: 'mp4', format: 'mp4', url: derivative_url('mp4') }])
      end

      def pdf_thumbnail_dir
        Rails.root.join("public/pdf_thumbnails")
      end

      def create_pdf_derivatives(filename)
        # Fix bug where filename is sometimes assigned to a directory
        filename = Dir["#{filename}/*"].first.to_s if File.directory?(filename)

        # If vips is installed
        if system "vips -v"
          create_vips_thumbnail(filename)
        else
          Hydra::Derivatives::PdfDerivatives.create(filename,
                                                    outputs: [{
                                                                  label: :thumbnail,
                                                                  format: 'jpg',
                                                                  size: '338x493',
                                                                  url: derivative_url('thumbnail'),
                                                                  layer: 0
                                                              }])
        end
        extract_full_text(filename, uri)
      end

      # Resize, create and save a thumbnail in assets directory
      # Find what collection the fileset belongs to and create a folder named after it
      # Use a "misc" folder if it's not in any collection.
      def create_vips_thumbnail(filepath)
        `vips thumbnail #{filepath} #{pdf_thumbnail_dir}/#{@file_set.id}-thumb.jpg 493x`
      end

  end
end
Hyrax::FileSetDerivativesService.prepend(Hyrax::FileSetDerivativesServiceDecorator)