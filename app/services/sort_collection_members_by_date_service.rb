class SortCollectionMembersByDateService < Hyrax::Collections::CollectionMemberService

  # @api public
  #
  # If no query or sort parameter is provided, sort works chronologically and then by title
  # @return [Blacklight::Solr::Response]
  def available_member_works
    if !params.key?(:sort) && !params.key?(:cq)
      response, _docs = search_results do |builder|
        builder.search_includes_models = :works
        builder.merge(sort: date_sort)
      end
      response
    else
      super
    end
  end

  private

  def date_sort
    "year_sort_dtsi asc, title_sort_ssi asc"
  end
end