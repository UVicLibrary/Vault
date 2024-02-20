class NestedWorksSearchService < Hyrax::Collections::CollectionMemberSearchService

  # @api public
  # @return [Blacklight::Solr::Response]
  def available_member_works
    response, _docs = search_results do |builder|
      builder.search_includes_models = :works
      # Search down the ancestor tree for works that are
      # members of subcollections
      builder.merge(fq: add_descendants(builder.query['fq']) )
      # If there is no sort or collection query specified,
      # sort by date_created and then alphabetically by title
      if !user_params.key?(:sort) && !user_params.key?(:cq)
        builder.merge(sort: date_sort)
      else
        # Fix bug where sort parameter was not coming through
        builder.merge(user_params.permit(:sort))
      end
    end
    response
  end

  private

  def add_descendants(fq)
    fq = fq.select(&:present?)
    members_filter = fq.delete("member_of_collection_ids_ssim:#{collection.id}")
    fq.push("(#{members_filter} OR #{ancestors_filter})")
  end

  def date_sort
    "year_sort_dtsi asc, title_sort_ssi asc"
  end

  def ancestors_filter
    ancestors_field = Samvera::NestingIndexer.configuration.solr_field_name_for_storing_ancestors
    "#{ancestors_field}:*#{collection.id}"
  end

end