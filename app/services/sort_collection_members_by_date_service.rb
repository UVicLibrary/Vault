class SortCollectionMembersByDateService < Hyrax::Collections::CollectionMemberSearchService

  # @api public
  #
  # If no query or sort parameter is provided, sort works chronologically and then by title
  # @return [Blacklight::Solr::Response]
  def available_member_works
    if !user_params.key?(:sort) && !user_params.key?(:cq)
      response, _docs = search_results do |builder|
        builder.search_includes_models = :works
        builder.merge(sort: date_sort)
      end
      response
    else
      # Fix bug where sorting parameters do not get passed in
      response, _docs = search_results do |builder|
        builder.merge(user_params.permit(:sort))
      end
      response
    end
  end

  private

  def date_sort
    "year_sort_dtsi asc, title_sort_ssi asc"
  end
end