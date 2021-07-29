class AudioFileSetThumbnailService < Hyrax::ThumbnailPathService
  class << self

    def call(object)
      collection = object.parent.member_of_collections
      if collection.any?
        Hyrax::ThumbnailPathService.call(collection.first)
      else
        audio_image
      end
    end

  end
end
