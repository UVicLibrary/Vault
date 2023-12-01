class CollectionIndexer < Hyrax::CollectionIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  include IndexesOAIFields

  # Use thumbnails served by RIIIF
  # self.thumbnail_path_service = IIIFCollectionThumbnailPathService
  self.thumbnail_path_service = CollectionThumbnailPathService

  def generate_solr_document
    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    object.to_controlled_vocab

    # This is any ugly patch to stop something (Active Fedora?) sometimes stuffing the Geonames' rdfs:seeAlso
    # attribute into the document's related_url field
    if object.related_url.any? { |val| val.include? "ActiveTriples" or val.include? "dbpedia" }
      object.related_url = object.related_url.reject { |val| val.include? "ActiveTriples" or val.include? "dbpedia" }
      object.save!
    end

    super.tap do |solr_doc|
      solr_doc['title_sort_ssi'] = object.title.first unless object.title.empty?

      # Index the size of the collection in bytes
      solr_doc['bytes_lts'] = object.bytes

      # Allow public users to see the metadata (so they can decide to request access or not)
      if object.visibility == "authenticated"
        solr_doc["discover_access_group_ssim"] = ["public"]
      end

      solr_doc['in_scua_bsi'] = object.in_scua
      solr_doc['location_sort_tesim'] = object.based_near.map { |val| GeonamesHierarchyService.call(val.id) }.flatten.uniq if object.based_near.present?
    end
  end
end
