class NestedWorksSearchService < Hyrax::Collections::CollectionMemberSearchService

  # @api public
  # @return [Blacklight::Solr::Response]
  def available_member_works
    response, _docs = search_results do |builder|
      builder.search_includes_models = :works
      # Include works that are members of subcollections
      builder.merge(fq: add_nested_descendants(builder.query['fq'], builder.collection.id))
      # If there is no sort or collection query specified,
      # sort by date_created and then alphabetically by title
      if !user_params.key?(:sort) && !user_params.key?(:cq)
        builder.merge(sort: default_sort)
      else
        builder.merge(user_params.permit(:sort))
      end
    end
    response
  end

  private

  # Replace the member_of_collection_ids_ssim filter with a query for nested children
  # using Solr's graph query parser
  def add_nested_descendants(fq, collection_id)
    # Solr can do graph traversal without the need of special indexing with the Graph query parser so
    # use this to compute the nested children of the current collection
    # See https://solr.apache.org/guide/solr/latest/query-guide/other-parsers.html#graph-query-parser
    fq.select(&:present?) - ["member_of_collection_ids_ssim:#{collection_id}"] +
      ["{!graph to=id from=member_of_collection_ids_ssim maxDepth=5}id:#{collection_id}"]
  end

  def default_sort
    "year_sort_dtsi asc, title_sort_ssi asc"
  end

end