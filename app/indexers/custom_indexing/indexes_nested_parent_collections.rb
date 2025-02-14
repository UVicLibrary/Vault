# frozen_string_literal: true
module IndexesNestedParentCollections
  extend ActiveSupport::Concern
  def generate_solr_document
    super.tap do |solr_doc|
      if object.member_of_collection_ids.any?
        solr_doc['nested_member_of_collections_ssim'] = NestedParentCollectionsService.nested_parent_collection_titles(object.id)
      end
    end
  end

end