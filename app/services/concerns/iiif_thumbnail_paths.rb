module IIIFThumbnailPaths
  extend ActiveSupport::Concern
  # Customized to use the latest version if a thumbnail has multiple versions

  class_methods do
    # @param [FileSet] file_set
    # @param [String] size ('!150,300') an IIIF image size defaults to an image no
    #                      wider than 150px and no taller than 300px
    # @return the IIIF url for the thumbnail if it's an image, otherwise gives
    #         the thumbnail download path
    def thumbnail_path(file_set, size = '!150,300'.freeze)
      iiif_thumbnail_path(file_set, size)
    end

    # @private
    def iiif_thumbnail_path(file_set, size)
      af_file_set = ::FileSet.find(file_set.id.to_s)
      return default_image unless af_file_set.original_file and af_file_set.image?

      # Use latest version
      if af_file_set.latest_content_version && af_file_set.latest_content_version.label != "version1"
        path = "#{af_file_set.original_file.id}/fcr:versions/#{af_file_set.latest_content_version.label}"
      elsif af_file_set
        path = af_file_set.original_file.id
      else
        path = file_set.original_file_id
      end
      Riiif::Engine.routes.url_helpers.image_path(
        path,
        size: size
      )
    end

  end
end
