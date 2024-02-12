class DownloadableCollectionMembersService < Hyrax::Collections::CollectionMemberSearchService

  ##
  # @api public
  #
  # Work ids of the works which are members of the given collection
  # and are publicly downloadable.
  # @return [Blacklight::Solr::Response]
  def available_member_work_ids
    response, _docs = search_results do |builder|
      builder.search_includes_models = :works
      builder.merge(
          fl: "id",
          fq: builder.query['fq'] << "download_access_group_ssim:public"
      )
      builder
    end
    response
  end

  # @return [Integer] The number of works in the given collection
  # that are publicly downloadable
  def downloadable_work_count
    available_member_work_ids.total
  end

end