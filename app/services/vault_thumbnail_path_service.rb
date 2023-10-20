  class VaultThumbnailPathService < Hyrax::ThumbnailPathService
    class << self

      # @param [Work, FileSet] object - to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image unless object.thumbnail_id
        thumb = fetch_thumbnail(object)
        return unless thumb
        return call(thumb) unless thumb.file_set?

        if audio?(thumb) || m4a_file?(thumb)
          audio_thumbnail_path(thumb)
        elsif thumbnail?(thumb)
          thumbnail_path(thumb)
        else
          default_image
        end
      end

      private

      # For now we go back to the ActiveFedora FileSet because Hyrax::FileSet
      # doesn't have the method .parent or .files.first.original_file_name,
      # which we need for pdf and audio thumbnails. Eventually this becomes
      # Hyrax.custom_queries.find_parent_work(resource: file_set) in v.3.5
      # https://github.com/samvera/hyrax/blob/main/app/models/hyrax/file_set.rb
      def fetch_thumbnail(object)
        # return object if object.thumbnail_id == object.id
        ActiveFedora::Base.find(object.thumbnail_id)
      end

      # Returns the value for the thumbnail path to put into the solr document
      def thumbnail_path(object)
        if pdf?(object)
          PdfThumbnailPathService.call(object)
        elsif video?(object)
          Hyrax::Engine.routes.url_helpers.download_path(object.id,
                                                         file: 'thumbnail')
        else
          IIIFWorkThumbnailPathService.call(object)
        end
      end

      def m4a_file?(object)
        # For a Hyrax::FileSet, .files.first.original_name can be replaced with
        # Hyrax.custom_queries.find_file_metadata_by(id: object.original_file_id).original_filename
        object.files.any? ? object.files.first.original_name.include?("m4a") : false
      end

      def audio_thumbnail_path(object)
        return audio_image unless (object.parent && object.parent.member_of_collections.any?)
        collection = object.parent.member_of_collections.first
        CollectionThumbnailPathService.call(collection)
      end

      # @return true if there a file on disk for this object, otherwise false
      # @param [FileSet] thumb - the object that is the thumbnail
      def thumbnail?(thumb)
        # Only videos use the default derivatives path. Images use IIIF thumbnails and
        # PdfThumbnailPathService does its own check for File.exist?
        return true unless video?(thumb)
        File.exist?(thumbnail_filepath(thumb))
      end

      def pdf?(thumb)
        service = thumb.respond_to?(:pdf?) ? thumb : Hyrax::FileSetTypeService.new(file_set: thumb)
        service.pdf?
      end

      def video?(thumb)
        service = thumb.respond_to?(:video?) ? thumb : Hyrax::FileSetTypeService.new(file_set: thumb)
        service.video?
      end

    end
  end
