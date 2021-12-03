class BrowseCollectionsSearchBuilder < Hyrax::CollectionSearchBuilder

# From Hyrax::CollectionSearchBuilder:
  # Our parent class is the generated SearchBuilder descending from Blacklight::SearchBuilder
  # It includes Blacklight::Solr::SearchBuilderBehavior, Hydra::AccessControlsEnforcement, Hyrax::SearchFilters
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb Blacklight::SearchBuilder parent
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb Blacklight::Solr::SearchBuilderBehavior
  # @see https://github.com/samvera/hyrax/blob/master/app/search_builders/hyrax/README.md SearchBuilders README
  # @note the default_processor_chain defined by Blacklight::Solr::SearchBuilderBehavior provides many possible points of override

  def sort_field
    "title_sort_ssi"
  end

  def default_sort_field
    "title_sort_ssi asc"
  end

end