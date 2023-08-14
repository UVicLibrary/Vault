class GoogleMapCollectionMembersService < Hyrax::Collections::CollectionMemberService

  # @return [Blacklight::SolrResponse]
  # Member works of a collection that have something in the coordinates field.
  # Call response.documents to view the Solr documents.
  # Call builder.query to see the params sent to Solr
  def available_member_works
    response, _docs = search_results do |builder|
      builder.search_includes_models = :works
      builder.merge(
          fl: filter_fields,
          fq: add_coordinates_filter(builder.query['fq']),
          rows: 3000)
    end
    response
  end

  def filter_fields
    %w(id coordinates_tesim thumbnail_path_ss description_tesim geographic_coverage_label_tesim title_tesim).join(', ')
  end

  def add_coordinates_filter(old_fq)
    old_fq << "coordinates_tesim:[* TO *]"
  end

end