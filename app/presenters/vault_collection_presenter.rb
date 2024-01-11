class VaultCollectionPresenter < Hyrax::CollectionPresenter

  # delegate fields from Hyrax::Works::Metadata to solr_document
  delegate :provider_label, :creator_label, :based_near_label, :subject_label,
           :contributor_label, :physical_repository_label, :genre_label,
           :geographic_coverage, :genre, :resource_type, :keyword,
           :geographic_coverage_label, :chronological_coverage, :thumbnail_path,
           to: :solr_document

  # Terms is the list of fields displayed by
  # app/views/collections/_show_descriptions.html.erb
  # In base hyrax, this gets expanded to include more terms.
  # However, we already display the extra terms in
  # _attribute_rows rather than _show_descriptions.
  def self.terms
    [:total_viewable_items, :size, :modified_date]
  end

  def terms_with_values
    self.class.terms.select { |t| self.send(t).present? }
  end

  def size
    number_to_human_size(@solr_document['bytes_lts'])
  end

  def user_can_feature_collections?
    current_ability.can?(:create, FeaturedCollection)
  end

  def collection_featurable?
    user_can_feature_collections? && solr_document.public?
  end

  def display_feature_link?
    collection_featurable? && FeaturedCollection.can_create_another? && !featured?
  end

  def display_unfeature_link?
    collection_featurable? && featured?
  end

  def featured?
    @featured = FeaturedCollection.where(collection_id: solr_document.id).exists? if @featured.nil?
    @featured
  end

  ##
  # @deprecated this implementation requires an extra db round trip, had a
  #   buggy cacheing mechanism, and was largely duplicative of other code.
  #   all versions of this code are replaced by
  #   {CollectionsHelper#available_parent_collections_data}.
  def available_parent_collections(scope:)
    Deprecation.warn("#{self.class}#available_parent_collections is " \
                       "deprecated. Use available_parent_collections_data " \
                       "helper instead.")
    return @available_parents if @available_parents.present?
    collection = ::Collection.find(id)
    colls = Hyrax::Collections::NestedCollectionQueryService
                .available_parent_collections(child: collection, scope: scope, limit_to_id: nil)
                .sort_by{ |coll| coll["title_sort_ssi"] }
    @available_parents = colls.map do |col|
      { "id" => col.id, "title_first" => col.title.first }
    end.to_json
  end

end