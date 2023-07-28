class CollectionThumbnailPathService < VaultThumbnailPathService
  # Returns the path for collection thumbnails, i.e.
  #   1. The path for an uploaded collection thumbnail, if it exists
  #   2. A 500x900 IIIF thumbnail selected from a member work. We select
  #       a larger respolution so that it still looks good on a homepage card.

  # app/services/concerns/iiif_thumbnail_paths.rb
  include IIIFThumbnailPaths
  # app/services/concerns/large_iiif_thumbnail_paths.rb
  include LargeIIIFThumbnailPaths

  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      if uploaded_thumbnail?(object)
        "/uploaded_collection_thumbnails/#{object.id}/#{object.id}_card.jpg"
      else
        return default_image unless object.thumbnail_id
        thumb = fetch_thumbnail(object)
        if thumbnail?(thumb)
          return download_path(thumb) if video?(thumb)
          thumbnail_path(thumb)
        else
          default_image
        end
      end
    end

    def upload_dir(collection)
      "#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}"
    end

    private

    # @return the network path to the thumbnail
    # @param [FileSet] thumbnail the object that is the thumbnail
    def download_path(thumbnail)
      Hyrax::Engine.routes.url_helpers.download_path(thumbnail.id,
                                                     file: 'thumbnail')
    end

    def uploaded_thumbnail?(collection)
      File.exist?("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg")
    end

    def default_image
      ActionController::Base.helpers.image_path 'collection.png'
    end

  end
end