class CollectionIndexer < Hyrax::CollectionIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Use thumbnails served by RIIIF
  self.thumbnail_path_service = IIIFCollectionThumbnailPathService

  def generate_solr_document
    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    object.attribute_names.each do |field|
      if object.controlled_properties.include?(field.to_sym) and object[field].present?
        to_controlled_vocab(field)
      end
    end

    super.tap do |solr_doc|
      solr_doc['title_sort_ssi'] = object.title.first unless object.title.empty?
    end
  end


  private

  # field is a symbol/controlled property
  # returns an array of Hyrax::ControlledVocabularies::[field]
  def to_controlled_vocab(field)
    if field.to_s == "based_near"
      class_name = "Hyrax::ControlledVocabularies::Location".constantize
    else
      class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
    end
    object[field] =  object[field].map do |val|
      val.include?("http") ? class_name.new(val.strip) : val
    end
  end


end
