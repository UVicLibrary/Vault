module CharacterizeJobDecorator

  # Use ruby-vips to check image for alpha channels instead of
  # MiniMagick/ImageMagick. Continuing to return srgba/srgb
  # to maintain compatibility with Hyrax::DisplaysImage
  # (used by the IIIF viewer to render images with transparency)
  #
  # @param[String] filepath - downloaded temp file
  def channels(filepath)
    Vips::Image.new_from_file(filepath).has_alpha? ? ["srgba"] : ["srgb"]
  end

end
CharacterizeJob.prepend(CharacterizeJobDecorator)