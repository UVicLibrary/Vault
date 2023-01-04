class SortCollectionMembersByDateSearchBuilder < Hyrax::CollectionMemberSearchBuilder

  def sort_field
    "year_sort_dtsi"
  end

  # If no query is supplied, sort results by date created, then by title
  def add_sorting_to_solr(solr_parameters)
    solr_parameters[:sort] ||= sort.present? ? sort : "#{sort_field} asc, title_sort_ssi asc"
  end

end