module LargeIIIFThumbnailPaths
  extend ActiveSupport::Concern
  # #iiif_thumbnail_path is defined in app/services/concerns/iiif_thumbnail_paths.rb
  LARGE_THUMBNAIL_SIZE = '!500,900'.freeze

  class_methods do
    # @param [FileSet] file_set
    # @param [String] size ('!500,900') an IIIF image size defaults to an image no
    #                      wider than 150px and no taller than 300px
    # @return the IIIF url for the thumbnail if it's an image, otherwise gives
    #         the thumbnail download path
    def thumbnail_path(file_set, size = LARGE_THUMBNAIL_SIZE)
      return super(file_set) unless file_set.try(:image?) || is_image?(file_set)
      iiif_thumbnail_path(file_set, size)
    end
  end

end
