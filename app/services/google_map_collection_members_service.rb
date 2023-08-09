class GoogleMapCollectionMembersService < Hyrax::Collections::CollectionMemberService

  # @return [Blacklight::SolrResponse]
  # Member works of a collection that have something in the coordinates field.
  # Call response.documents to view the Solr documents.
  # Call builder.query to see the params sent to Solr
  def available_member_works
    builder = works_search_builder.merge(
                   fq: add_coordinates_filter(works_search_builder.query['fq']),
                   rows: 3000)
    query_solr_with_field_selection(query_builder: builder, fl: filter_fields)
  end

  def filter_fields
    %w(coordinates_tesim thumbnail_path_ss description_tesim geographic_coverage_label_tesim title_tesim).join(', ')
  end

  def add_coordinates_filter(old_fq)
    old_fq << "coordinates_tesim:[* TO *]"
  end

end