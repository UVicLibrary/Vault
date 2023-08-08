class GoogleMapCollectionMembersService < Hyrax::Collections::CollectionMemberService

  # @return [Blacklight::SolrResponse]
  # Member works of a collection that have something in the coordinates field.
  # Call response.documents to view the Solr documents.
  # Call builder.query to see the params sent to Solr
  def available_member_works
    query_solr(query_builder: works_search_builder.merge(
                                  fq: "coordinates_tesim:[* TO *]",
                                  fl: filter_fields,
                                  rows: 3000),
               query_params: {})
  end

  def filter_fields
    %w(coordinates_tesim thumbnail_path_ss description_tesim geographic_coverage_label_tesim title_tesim).join(', ')
  end

end