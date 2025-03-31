require 'ruby-vips'
module Hydra::Derivatives::Processors::ImageDecorator

  protected

  # When resizing images, it is necessary to flatten any layers, otherwise the background
  # may be completely black. This happens especially with PDFs. See #110
  def create_resized_image
    if Hydra::Derivatives::ImageService.processor == :graphicsmagick
      create_resized_image_with_graphicsmagick
    elsif Hydra::Derivatives::ImageService.processor == :libvips
      create_resized_image_with_libvips
    else
      create_resized_image_with_imagemagick
    end
  end

  def create_resized_image_with_libvips
    Hydra::Derivatives::Logger.debug('[ImageProcessor] Using libvips resize method')
    create_image do |temp_file|
      if size
        width, height, option = size.match(/(\d+)x(\d+)(.)?/).captures
        # Translate imagemagick resize syntax into ruby-vips
        size_option = case option
          when '>'
            :down
          when '<'
            :up
          when '!'
            :force
        end
        temp_file.thumbnail_image(width.to_i, height: height.to_i, size: size_option)
      end
    end
  end

  def create_image
    if Hydra::Derivatives::ImageService.processor == :libvips
      image = block_given? ? yield(load_image_transformer) : load_image_transformer
      write_image_with_vips(image, directives)
    else
      xfrm = selected_layers(load_image_transformer)
      yield(xfrm) if block_given?
      xfrm.format(directives.fetch(:format))
      xfrm.quality(quality.to_s) if quality
      write_image(xfrm)
    end
  end

  def write_image_with_vips(image, directives)
    output_io = StringIO.new
    format = directives.fetch(:format, "jpg")
    quality = directives.fetch(:quality, nil)
    format_string = ".#{format}#{"[Q=#{quality}]" if quality}"
    output_io.write(image.write_to_buffer(format_string))
    output_io.rewind
    output_file_service.call(output_io, directives)
  end

  def load_image_transformer
    if Hydra::Derivatives::ImageService.processor == :libvips
      Vips::Image.new_from_file(source_path)
    else
      MiniMagick::Image.open(source_path)
    end
  end

end
Hydra::Derivatives::Processors::Image.prepend(Hydra::Derivatives::Processors::ImageDecorator)