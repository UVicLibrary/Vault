class CollectionThumbnailPathService < Hyrax::CollectionThumbnailPathService
  # Returns the path for collection thumbnails, i.e.
  #   1. The path for an uploaded collection thumbnail, if any
  #   2. A larger resolution path for an IIIF thumbnail than the default option
  #       (originally this is 100x300). This is so that it still looks in a
  #       homepage card.

  include IIIFThumbnailPaths

  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      if uploaded_thumbnail?(object)
        "/uploaded_collection_thumbnails/#{object.id}/#{object.id}_card.jpg"
      elsif object.thumbnail.present?
        thumbnail_path(object.thumbnail, '!500,900')
      else
        default_image
      end
    end

    def uploaded_thumbnail?(collection)
      File.exist?("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg")
    end

    def upload_dir(collection)
      "#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection.id}"
    end

    # @param [FileSet] file_set
    # @param [String] size ('!500,900') an IIIF image size defaults to an image no
    #                      wider than 150px and no taller than 300px
    # @return the IIIF url for the thumbnail if it's an image, otherwise gives
    #         the thumbnail download path
    # def thumbnail_path(file_set, size = '!500,900'.freeze)
    #   iiif_thumbnail_path(file_set, size)
    # end

  end
end
