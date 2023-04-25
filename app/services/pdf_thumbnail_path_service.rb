class PdfThumbnailPathService < Hyrax::WorkThumbnailPathService
  # We use poppler to generate pdf thumbnails instead of ImageMagick/MiniMagick.
  # (See file set derivatives service.) Index that new path into the thumbnail
  # field for works.

  class << self

    # @param [file set] object - to get the thumbnail for
    # @return [String] a path to the thumbnail
    def call(object)
      if in_collection?(object) && File.exist?("#{public_path}#{coll_path(collection_title(object), object.id)}")
        coll_path(collection_title(object), object.id)
      elsif in_collection?(object)
        default_image
      elsif File.exist?("#{public_path}#{misc_path(object.id)}")
        misc_path(object.id)
      else
        default_image
      end
    end

  private

    def in_collection?(file_set)
      return false unless file_set.parent
      file_set.parent.member_of_collections.any? ? true : false
    end

    def collection_title(file_set)
      file_set.parent.member_of_collections.first.title.first.parameterize.underscore
    end

    def coll_path(collection_title, file_set_id)
      "/pdf_thumbnails/#{collection_title}/#{file_set_id}-thumb.jpg"
    end

    def misc_path(file_set_id)
      "/pdf_thumbnails/misc/#{file_set_id}-thumb.jpg"
    end

    # Path to public folder
    def public_path
      "#{Rails.root.to_s}/public"
    end

  end
end
