require_dependency Hyrax::Engine.root.join('app/indexers/hyrax/basic_metadata_indexer.rb')

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::BasicMetadataIndexer.class_eval do

  # Compared to original fields: +provider, +physical_repository, +geographic_coveragte, +genre
  #                              +date_created, +year
  self.stored_and_facetable_fields = %i[resource_type creator contributor keyword
                                        publisher subject language based_near provider
                                        physical_repository geographic_coverage
                                        genre date_created year]

  # Compared to original fields: -related_url, -identifier
  self.stored_fields = %i[description license rights_statement bibliographic_citation source]

end