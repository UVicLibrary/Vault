module NestedCollectionFacetBehavior
  # Last updated for Blacklight v.7.38, Hyrax 4.0

  def configure_collection_facet
    if self.current_account.presence
      # Call :add_facet_field so that Blacklight can build the
      # facet configuration instead of doing it ourselves
      blacklight_config.add_facet_field 'member_of_collections_ssim', label: 'Collection', query: build_collection_facets
      # Move the collection facet to the top of the list so it renders first
      reorder_collection_facets
    end
  end

  private

  # @return [<Hash] - collection info that Blacklight needs to configure the facet
  # See https://workshop.projectblacklight.org/v7.11.1/facet_fields/#query-facets
  def build_collection_facets
    collections = Hyrax::SolrService.get(
                    fq: ["has_model_ssim:Collection"],
                    rows: 5000, # Set to a comically huge number
                    fl: "id, title_sort_ssi"
                  )['response']['docs']

    collections.each_with_object({}) do |document, facet_hash|
      facet_hash[document['title_sort_ssi'].to_sym] =
          { label: document["title_sort_ssi"],
            fq: NestedWorksSearchService.nested_members_query(document['id']) }
    end
  end

  def reorder_collection_facets
    collection_facet = blacklight_config.facet_fields.delete('member_of_collections_ssim')
    other_facets = blacklight_config.facet_fields
    blacklight_config.facet_fields = { 'member_of_collections_ssim' => collection_facet }.merge(other_facets)
  end

end