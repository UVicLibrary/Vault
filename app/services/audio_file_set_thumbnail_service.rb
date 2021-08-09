class AudioFileSetThumbnailService < Hyrax::ThumbnailPathService
  class << self

    def call(object)
      if object.parent
        collection = object.parent.member_of_collections
      else
        return audio_image
      end

      if collection.any? and (collection.first.thumbnail.present? or uploaded_thumbnail?(collection.first.id))
        if uploaded_thumbnail?(collection.first.id)
          UploadedCollectionThumbnailPathService.call(collection.first)
        else
          Hyrax::ThumbnailPathService.call(collection.first)
        end
      else
        audio_image
      end
    end

    private

      # Check if there is an uploaded thumbnail for a collection
      def uploaded_thumbnail?(collection_id)
        File.exist?("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{collection_id}/#{collection_id}_thumbnail.jpg")
      end

  end
end
