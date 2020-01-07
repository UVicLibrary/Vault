class UploadedCollectionThumbnailPathService < Hyrax::ThumbnailPathService
  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      "/uploaded_collection_thumbnails/#{object.id}/#{object.id}_thumbnail.jpg"
    end
  end
end
