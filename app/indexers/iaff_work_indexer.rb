# Generated via
#  `rails generate hyrax:work IaffWork`
class IaffWorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Uncomment this block if you want to add custom indexing behavior:
   def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['genre_tesim'] = object.genre
      solr_doc['identifier_tesim'] = object.identifier
      solr_doc['related_url_tesim'] = object.related_url
    end
   end
end
