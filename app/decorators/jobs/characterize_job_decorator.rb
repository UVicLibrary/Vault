# OVERRIDE Hyrax 4.0
#   - Queue CreateDerivativesJob after performing this one
#   - Use libvips instead of ImageMagick for detecting alpha channels
module CharacterizeJobDecorator
  def perform(file_set, file_id, filepath = nil)
    super
    CreateDerivativesJob.perform_later(file_set, file_id, filepath)
  end

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