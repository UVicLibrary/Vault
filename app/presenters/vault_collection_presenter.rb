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
    [:total_viewable_items, :modified_date]
  end

  def terms_with_values
    self.class.terms.select { |t| self.send(t).present? }
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

  def total_viewable_items
    Hyrax::SolrService.get(query_for_ability,
                           fq: nested_members_query)['response']['numFound']
  end

  def total_viewable_works
    filter_query = "(#{nested_members_query}) AND has_model_ssim:GenericWork"

    Hyrax::SolrService.get(query_for_ability,
                           fq: filter_query)['response']['numFound']
  end

  def total_viewable_collections
    filter_query = "(#{nested_members_query}) AND has_model_ssim:Collection"

    Hyrax::SolrService.get(query_for_ability,
                           fq: filter_query)['response']['numFound']
  end

  def nested_members_query
    ["nesting_collection__ancestors_ssim:*#{id.to_s}",
     "member_of_collection_ids_ssim:#{id.to_s}"].join(" OR ")
  end

  def query_for_ability
    Hyrax::SolrQueryService.new.accessible_by(ability: current_ability).query.first
  end

end