# Based on Hyrax 4.0's FileSetDerivatvesService
#   - Omit creation of image derivatives
#   - Use libvips (instead of ImageMagick) to create PDF derivatives
class VipsDerivativesService < Hyrax::FileSetDerivativesService
  extend ActiveSupport::Concern

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
    `vips thumbnail "#{filepath}" #{pdf_thumbnail_dir}/#{@file_set.id}-thumb.jpg 493x`
  end

  def pdf_thumbnail_dir
    Rails.root.join("public/pdf_thumbnails")
  end

  # @return [String] The url to the
  def pdf_thumbnail_url
    dir = pdf_thumbnail_dir.to_s.gsub(Rails.root.to_s,'').gsub('/public','')
    "#{dir}/#{@file_set.id}-thumb.jpg"
  end

  def create_image_derivatives(_)
    # Left intentionally blank. We don't need to create image derivatives since we use IIIF for them.
  end

end