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
      return default_image unless file_set.try(:image?) || is_image?(file_set)

      # file_set will be an ActiveFedora FileSet when indexing a file set
      # and a Hyrax::FileSet when indexing a work
      path = if file_set.is_a? Hyrax::FileSet
               file = Hyrax.custom_queries.find_file_metadata_by(id: file_set.original_file_id)
               Hyrax.config.translate_uri_to_id.call(
                   Hyrax::VersioningService.versioned_file_id(file)
               )
             else # ActiveFedora file set (file_set.class.ancestors.include?(ActiveFedora::Base))
               file = ActiveFedora::Base.find(file_set.id.to_s).original_file
               Hyrax::VersioningService.versioned_file_id(file)
             end

      Riiif::Engine.routes.url_helpers.image_path(
        path,
        size: size
      )
    end

    # @param [Hyrax::FileSet]
    def is_image?(file_set)
      return false unless file_set.respond_to?(:original_file_id)
      Hyrax.custom_queries.find_file_metadata_by(id: file_set.original_file_id).image?
    end

  end
end
