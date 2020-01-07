# Generated via
#  `rails generate curation_concerns:work GenericWork`
module Hyrax
  class GenericWorkForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::GenericWork
    include HydraEditor::Form::Permissions
    self.terms += [:resource_type, :alternative_title, :license, :edition, :geographic_coverage, :coordinates, :chronological_coverage, :extent, :additional_physical_characteristics, :has_format, :physical_repository, :collection, :provenance, :provider, :sponsor, :genre, :format, :archival_item_identifier, :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier, :is_referenced_by, :date_digitized, :transcript, :technical_note, :year]
    self.required_fields += [:provider] 
    self.required_fields -= [:keyword]
    def self.secondary_terms
        terms - required_fields -
          [:files, :visibility_during_embargo, :embargo_release_date,
           :visibility_after_embargo, :visibility_during_lease,
           :lease_expiration_date, :visibility_after_lease, :visibility,
           :thumbnail_id, :representative_id, :ordered_member_ids,
           :collection_ids, :in_works_ids, :admin_set_id, :rendering_ids]
    end

    def self.build_permitted_params
    	super + [
    	{
            creator_attributes: [:id, :_destroy],
            contributor_attributes: [:id, :_destroy],
            physical_repository_attributes: [:id, :_destroy],
            provider_attributes: [:id, :_destroy],
            subject_attributes: [:id, :_destroy],
            geographic_coverage_attributes: [:id, :_destroy],
            genre_attributes: [:id, :_destroy]
          }
      ]
    end
      
#    self.terms += [:resource_type, :rendering_ids]

#    def secondary_terms
#      super - [:rendering_ids]
#    end

  #self.rendering_ids = self.required_fields
  def rendering_ids
    to_param
  end
  end
end
