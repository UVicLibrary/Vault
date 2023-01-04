class SortCollectionMembersByDateService < Hyrax::Collections::CollectionMemberService

  # @api public
  #
  # If no query or sort parameter is provided, sort works chronologically and then by title
  # @return [Blacklight::Solr::Response]
  def available_member_works
    if !params.key?(:sort) && !params.key?(:cq)
      query_solr(query_builder: works_search_builder, query_params: params.merge(sort: date_sort))
    else
      Rails.logger.warn("params = #{params}")
      query_solr(query_builder: works_search_builder, query_params: params)
    end
  end

  private

  # @api private
  #
  # set up a member search builder for works only
  # @return [SortCollectionMembersByDateSearchBuilder] new or existing
  def works_search_builder
    @works_search_builder ||= SortCollectionMembersByDateSearchBuilder.new(scope: scope, collection: collection, search_includes_models: :works)
  end

  def date_sort
    "year_sort_dtsi asc, title_sort_ssi asc"
  end
end