class PdfThumbnailPathService < Hyrax::WorkThumbnailPathService
  # We use poppler to generate pdf thumbnails instead of ImageMagick/MiniMagick.
  # (See file set derivatives service.) Index that new path into the thumbnail
  # field for works.

  class << self

    # @param [file set] object - to get the thumbnail for
    # @return [String] a path to the thumbnail
    def call(object)
      return default_image if object.try(:thumbnail_id).blank?

      thumb = fetch_thumbnail(object)

      return default_image unless thumb
      return call(thumb) unless thumb.file_set?
      collection = object.parent.member_of_collections
      collection_name = object.parent.member_of_collections.first.title.first.parameterize.underscore if collection.any?
      if collection_name && File.exist?("#{public_path}#{pdf_path(collection_name, object.id)}")
        pdf_path(collection_name, object.id)
      elsif File.exist?("#{public_path}#{pdf_path(collection_name, object.id)}")
        misc_path(object.id)
      else
        default_image
      end
    end

  private

    def pdf_path(collection_title, file_set_id)
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
