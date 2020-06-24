class FileSetIndexer < Hyrax::FileSetIndexer
	include Hyrax::IndexesLinkedMetadata
  self.thumbnail_path_service = IIIFWorkThumbnailPathService
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['hasFormat_ssim'] = object.rendering_ids
      if object.creator.present?
        solr_doc['creator_tesim'] = Array.wrap(object.creator.first.id) 
        solr_doc['creator_label_tesim'] = object.creator.first.rdf_label
      end
    end
  end
end
