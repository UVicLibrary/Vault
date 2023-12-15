# Override Hyrax 3.1
Hyrax::CollectionsHelper.module_eval do
  ##
  # @since 3.1.0
  # @return [Array<SolrDocument>]
  def available_child_collections(collection:)
    Hyrax::Collections::NestedCollectionQueryService
      .available_child_collections(parent: collection, scope: controller, limit_to_id: nil).sort_by{ |coll| coll["title_sort_ssi"]}
  end

  ##
  # @since 3.1.0
  #
  # @note provides data for handleAddToCollection javascript
  #
  # @return [String] JSON document containing id/title pairs for eligible
  #   parent collections to be displayed in an "Add to Collection" dropdown
  def available_parent_collections_data(collection:)
    Hyrax::Collections::NestedCollectionQueryService
      .available_parent_collections(child: collection, scope: controller, limit_to_id: nil)
  end
end