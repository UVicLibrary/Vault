# Based on Hyrax 4.0's FileSetDerivatvesService
#   - Omit creation of video derivatives other than thumbnail
#   - Use libvips (instead of ImageMagick) to create image & PDF derivatives
class VipsDerivativesService < Hyrax::FileSetDerivativesService
  extend ActiveSupport::Concern

  # Overriding to omit webm files because it takes way too long
  def create_video_derivatives(filename)
    Hydra::Derivatives::VideoDerivatives.create(filename,
                                                outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') }])
  end

  def create_pdf_derivatives(filename)
    # We are transitioning from saving PDF thumbnails in the public
    # folder back to the Hyrax default URL ("downloads/#{file_set.id}?file=thumbnail")
    # now that hydra-derivatves has been configured to use libvips.
    #
    # For now, we will create thumbnails in both places. Once all PDF
    # thumbs have been regenerated, we will switch back to using
    # hydra-derivatives only.
    create_vips_thumbnail(filename)
    Hydra::Derivatives::PdfDerivatives.create(filename,
                                              outputs: [{
                                                          label: :thumbnail,
                                                          format: 'jpg',
                                                          size: '250x250>',
                                                          quality: 65,
                                                          url: derivative_url('thumbnail'),
                                                          layer: 0
                                                        }])
    extract_full_text(filename, uri)
  end

  # Resize, create and save a thumbnail in the public directory
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

  def create_image_derivatives(filename)
    # We're asking for layer 0, because otherwise pyramidal tiffs flatten all the layers together into the thumbnail
    Hydra::Derivatives::ImageDerivatives.create(filename,
                                                outputs: [{ label: :thumbnail,
                                                            format: 'jpg',
                                                            size: '250x250>',
                                                            quality: 65,
                                                            url: derivative_url('thumbnail'),
                                                            layer: 0 }])
  end

end