# frozen_string_literal: true
class CollectionThumbnailPathService < VaultThumbnailPathService
  # Returns the path for collection thumbnails, i.e.
  #   1. The path for an uploaded collection thumbnail, if it exists
  #   2. A 500x900 IIIF thumbnail selected from a member work. We select
  #       a larger respolution so that it still looks good on a homepage card.
  class << self

    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      if UploadedCollectionThumbnailPathService.uploaded_thumbnail?(object)
        UploadedCollectionThumbnailPathService.call(object)
      else
        return default_image if object.try(:thumbnail_id).blank?
        super(object)
      end
    end

    def image_thumbnail_size
      '!500,900'
    end

    private

    def default_image
      Hyrax::CollectionThumbnailPathService.default_image
    end

  end
end