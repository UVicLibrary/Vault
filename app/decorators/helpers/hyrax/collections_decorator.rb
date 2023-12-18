# Override Hyrax 3.1
Hyrax::CollectionsHelper.module_eval do
  ##
  # @since 3.1.0
  # @return [Array<SolrDocument>]
  def available_child_collections(collection:)
    return @available_children if @available_children.present?
    colls = Hyrax::Collections::NestedCollectionQueryService
      .available_child_collections(parent: collection, scope: controller, limit_to_id: nil).sort_by{ |coll| coll["title_sort_ssi"]}
    @available_children = colls.map do |col|
      { "id" => col.id, "title_first" => col.title.first }
    end.to_json
  end

  ##
  # @since 3.1.0
  #
  # @note provides data for handleAddToCollection javascript
  #
  # @return [String] JSON document containing id/title pairs for eligible
  #   parent collections to be displayed in an "Add to Collection" dropdown
  def available_parent_collections_data(collection:)
    return @available_parents if @available_parents.present?
    colls = Hyrax::Collections::NestedCollectionQueryService
      .available_parent_collections(child: collection, scope: controller, limit_to_id: nil).sort_by{ |coll| coll["title_sort_ssi"]}
    @available_parents = colls.map do |col|
      { "id" => col.id, "title_first" => col.title.first }
    end.to_json
  end
end