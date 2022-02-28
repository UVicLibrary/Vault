class UploadedCollectionThumbnailPathService < Hyrax::ThumbnailPathService
  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      "/uploaded_collection_thumbnails/#{object.id}/#{object.id}_card.jpg"
    end

    def uploaded_thumbnail?(collection)
      File.exist?("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg")
    end

    def upload_dir(collection)
      "#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}"
    end

  end
end
