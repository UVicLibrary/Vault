class AudioFileSetThumbnailService < Hyrax::ThumbnailPathService
  class << self

    def call(object)
      if object.parent
        collection = object.parent.member_of_collections.first
      else
        audio_image
      end

      if collection.present? && (collection.thumbnail.present? || UploadedCollectionThumbnailPathService.uploaded_thumbnail?(collection))
        if UploadedCollectionThumbnailPathService.uploaded_thumbnail?(collection)
          UploadedCollectionThumbnailPathService.call(collection)
        else
          IIIFCollectionThumbnailPathService.call(collection)
        end
      else
        audio_image
      end
    end

  end
end
