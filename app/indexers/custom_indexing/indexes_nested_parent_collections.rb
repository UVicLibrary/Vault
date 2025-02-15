# frozen_string_literal: true
module IndexesNestedParentCollections
  extend ActiveSupport::Concern
  def generate_solr_document
    super.tap do |solr_doc|
      if object.parent_collections.any?

        # Need this line for collections since newly-added direct parents
        # will not yet be captured by the Solr search
        new_collection_parents = object.parent_collections.map(&:title).map(&:to_a).flatten

        solr_doc['nested_member_of_collections_ssim'] =
          (new_collection_parents + NestedParentCollectionsService.nested_parent_collection_titles(object.id)).uniq
      end
    end
  end

end