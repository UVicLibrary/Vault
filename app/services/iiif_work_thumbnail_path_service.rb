class IIIFWorkThumbnailPathService < Hyrax::WorkThumbnailPathService
  include IIIFThumbnailPaths
  # This is here to divert image thumbnails away from Hyrax::ThumbnailPathService
  class << self

    def call(object)
      thumbnail_path(object)
    end

  end

end
