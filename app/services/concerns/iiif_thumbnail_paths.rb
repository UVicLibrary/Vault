module IIIFThumbnailPaths
  extend ActiveSupport::Concern
  # Customized to use the latest version if a thumbnail has multiple versions

  THUMBNAIL_SIZE = '!150,300'.freeze

  class_methods do
    # @param [FileSet] file_set
    # @param [String] size ('!150,300') an IIIF image size defaults to an image no
    #                      wider than 150px and no taller than 300px
    # @return the IIIF url for the thumbnail if it's an image, otherwise gives
    #         the thumbnail download path
    def thumbnail_path(file_set, size = THUMBNAIL_SIZE)
      iiif_thumbnail_path(file_set, size)
    end

    # @private
    def iiif_thumbnail_path(file_set, size)
      af_file_set = ::FileSet.find(file_set.id.to_s)
      return default_image unless af_file_set.original_file and af_file_set.image?

      # Use latest version
      path = Hyrax::VersioningService.versioned_file_id(af_file_set.original_file)
      Riiif::Engine.routes.url_helpers.image_path(
        path,
        size: size
      )
    end

  end
end
