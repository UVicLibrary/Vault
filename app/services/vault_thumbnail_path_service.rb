  class VaultThumbnailPathService < Hyrax::ThumbnailPathService
    class << self

      # @param [Work, FileSet] object - to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image unless object.thumbnail_id

        thumb = fetch_thumbnail(object)
        return unless thumb
        return call(thumb) unless thumb.is_a?(::FileSet)

        if thumb.audio? || m4a_file?(thumb)
          audio_thumbnail_path(thumb)
        elsif thumbnail?(thumb)
          thumbnail_path(thumb)
        else
          default_image
        end
      end

      private

      # Returns the value for the thumbnail path to put into the solr document
      def thumbnail_path(object)
        if object.pdf?
          PdfThumbnailPathService.call(object.thumbnail)
        else
          IIIFWorkThumbnailPathService.call(object)
        end
      end

      def m4a_file?(object)
        object.label && object.label.include?(".m4a")
      end

      def audio_thumbnail_path(object)
        return audio_image unless (object.parent && object.parent.member_of_collections.any?)
        collection = object.parent.member_of_collections.first
        CollectionThumbnailPathService.call(collection)
      end

    end
  end
