class FileSetIndexer < Hyrax::FileSetIndexer
  include Hyrax::IndexesLinkedMetadata
  self.thumbnail_path_service = IIIFWorkThumbnailPathService

  def generate_solr_document
    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    object.attribute_names.each do |field|
      if object.controlled_properties.include?(field.to_sym) and object[field].present?
        to_controlled_vocab(field)
      end
    end

    super.tap do |solr_doc|
      solr_doc['hasFormat_ssim'] = object.rendering_ids
        #if object.creator.present?
        #  solr_doc['creator_tesim'] = Array.wrap(object.creator.first.id)
        #  solr_doc['creator_label_tesim'] = object.creator.first.rdf_label
        #end
      end
    end
  end

  private
  # term is a symbol/controlled property
  # returns an array of Hyrax::ControlledVocabularies::[term]
  def to_controlled_vocab(field)
    if field.to_s == "based_near"
      class_name = "Hyrax::ControlledVocabularies::Location".constantize
    else
      class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
    end
    object[field] =  object[field].map { |val| class_name.new(val) }
  end

end

