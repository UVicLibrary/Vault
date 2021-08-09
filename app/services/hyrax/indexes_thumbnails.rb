module Hyrax
  module IndexesThumbnails
    extend ActiveSupport::Concern

    included do
      class_attribute :thumbnail_path_service
      self.thumbnail_path_service = ThumbnailPathService
      class_attribute :thumbnail_field
      self.thumbnail_field = 'thumbnail_path_ss'.freeze
    end

    # Adds thumbnail indexing to the solr document
    def generate_solr_document
      super.tap do |solr_doc|
        index_thumbnails(solr_doc)
      end
    end

    # Write the thumbnail paths into the solr_document
    # @param [Hash] solr_document the solr document to add the field to
    def index_thumbnails(solr_document)
      solr_document[thumbnail_field] = thumbnail_path
    end

    # Check if there is an uploaded thumbnail for a collection
    def uploaded_thumbnail?(solr_document_id)
      File.exist?("#{Rails.root.to_s}/public/uploaded_collection_thumbnails/#{solr_document_id}/#{solr_document_id}_thumbnail.jpg")
    end

    # Returns the value for the thumbnail path to put into the solr document
    def thumbnail_path
      if self.object.class == Collection && uploaded_thumbnail?(self.object.id)
        UploadedCollectionThumbnailPathService.call(object)
      elsif self.object.is_a?(::FileSet) && (self.object.audio? or self.object.files.first.file_name.firstinclude?(".m4a"))
        AudioFileSetThumbnailService.call(object)
      else
        self.class.thumbnail_path_service.call(object)
      end
    end
  end
end
