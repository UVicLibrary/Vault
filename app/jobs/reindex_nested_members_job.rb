class ReindexNestedMembersJob < ActiveJob::Base

  # @param [String] - the parent collection id
  def perform(collection_id)
    query = NestedWorksSearchService.nested_members_query(collection_id)
    Hyrax::SolrService.get(query, fl: 'id')['response']['docs'].map do |doc|
      ReindexObjectJob.perform_later(doc['id'])
    end
  end

end