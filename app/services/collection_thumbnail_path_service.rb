class CollectionThumbnailPathService < Hyrax::ThumbnailPathService
  # Returns the path for collection thumbnails, i.e.
  #   1. The path for an uploaded collection thumbnail, if any
  #   2. A larger resolution path for an IIIF thumbnail than the default option
  #  (originally this is 100x300). This is so that it still looks good
  #   on a homepage card.


  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      if uploaded_thumbnail?(object)
        "/uploaded_collection_thumbnails/#{object.id}/#{object.id}_card.jpg"
      else
        IIIFCollectionThumbnailPathService.call(object)
      end
    end

    def uploaded_thumbnail?(collection)
      File.exist?("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg")
    end

    def upload_dir(collection)
      "#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}"
    end

  end
end
