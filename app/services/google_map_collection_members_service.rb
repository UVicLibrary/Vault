class GoogleMapCollectionMembersService < Hyrax::Collections::CollectionMemberService

  def available_member_works
    query_solr_with_field_selection(
        query_builder: works_search_builder.with(fq: 'coordinates_tesim: [* TO *]', rows: 3000),
        fl: filter_fields
    )
  end

  def filter_fields
    %w(coordinates_tesim thumbnail_path_ss description_tesim geographic_coverage_label_tesim title_tesim).join(', ')
  end

end