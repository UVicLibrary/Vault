class NestedWorksSearchService < Hyrax::Collections::CollectionMemberSearchService

  # @api public
  # Returns nested members (collectins & works) of a given collection.
  # This is used on a collection show page.
  # @return [Blacklight::Solr::Response]
  def available_member_works
    response, _docs = search_results do |builder|
      builder.search_includes_models = :works

      # Set the sort to relevance if a search term is provided
      # without a sort parameter
      if builder.blacklight_params['cq'].present? && builder.blacklight_params['sort'].blank?
        builder.merge(sort: "score desc")
        # Merge the sort into parameters so the interface/dropdown
        # displays the correct sort option
        params.merge!(sort: "score desc")
      end

      # Include works that are members of subcollections
      builder.merge(fq: add_nested_descendants(builder.query['fq'], builder.collection.id))
    end
    response
  end

  def self.nested_members_query(collection_id)
    "({!graph to=id from=member_of_collection_ids_ssim maxDepth=5}id:#{collection_id}) AND -id:#{collection_id}"
  end

  private

  # Replace the member_of_collection_ids_ssim filter with a query for nested children
  # using Solr's graph query parser
  def add_nested_descendants(fq, collection_id)
    # Solr can do graph traversal without the need of special indexing with the Graph query parser so
    # use this to compute the nested children of the current collection
    # See https://solr.apache.org/guide/solr/latest/query-guide/other-parsers.html#graph-query-parser
    fq.select(&:present?) - ["member_of_collection_ids_ssim:#{collection_id}"] +
      [self.class.nested_members_query(collection_id)]
  end

end