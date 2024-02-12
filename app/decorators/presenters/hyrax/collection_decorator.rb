require_dependency Hyrax::Engine.root.join('app/presenters/hyrax/collection_presenter.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::CollectionPresenter.class_eval do

  def total_viewable_items
    field_pairs = {
                    "nesting_collection__ancestors_ssim" => id.to_s,
                    "member_of_collection_ids_ssim" => id.to_s
                  }

    Hyrax::SolrQueryService.new
        .with_field_pairs(field_pairs: field_pairs, join_with: ' OR ')
        .accessible_by(ability: current_ability)
        .count
  end

  def total_viewable_works
    field_pairs = {
                    "nesting_collection__ancestors_ssim" => id.to_s,
                    "member_of_collection_ids_ssim" => id.to_s
                  }

    Hyrax::SolrQueryService.new
        .with_field_pairs(field_pairs: field_pairs, join_with: ' OR ')
        .with_generic_type(generic_type: "Work")
        .accessible_by(ability: current_ability)
        .count
  end

  def total_viewable_collections
    field_pairs = {
                    "nesting_collection__ancestors_ssim" => id.to_s,
                    "member_of_collection_ids_ssim" => id.to_s
                  }

    Hyrax::SolrQueryService.new
        .with_field_pairs(field_pairs: field_pairs, join_with: ' OR ')
        .with_generic_type(generic_type: "Collection")
        .accessible_by(ability: current_ability)
        .count
  end

end