# frozen_string_literal: true

# This service fetches parent collections' titles for indexing into work
# and collection documents. The resulting indexed field supports the
# catalog search's collection facet.
class NestedParentCollectionsService < Hyrax::CollectionsService
  class << self

    # @param [String] - the id of a work or collection
    def nested_parent_collection_titles(object_id)
      Hyrax::SolrService.get(
        nested_parents_query(object_id),
        fl: 'title_sort_ssi'
      )['response']['docs'].map { |doc| doc['title_sort_ssi'] }
    end

    private

    def nested_parents_query(object_id)
      "({!graph to=member_of_collection_ids_ssim from=id maxDepth=5}id:#{object_id}) AND -id:#{object_id}"
    end

  end
end
