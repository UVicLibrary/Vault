# Generated via
#  `rails generate curation_concerns:work GenericWork`
module Hyrax
  class GenericWorkForm < Hyrax::Forms::WorkForm
    # Adds behaviors for hyrax-doi plugin.
    include Hyrax::DOI::DOIFormBehavior
    # Adds behaviors for DataCite DOIs via hyrax-doi plugin.
    include Hyrax::DOI::DataCiteDOIFormBehavior

    self.model_class = ::GenericWork
    include HydraEditor::Form::Permissions

    self.terms += [:resource_type, :edition, :geographic_coverage,
                   :coordinates, :chronological_coverage, :extent, :additional_physical_characteristics,
                   :has_format, :physical_repository, :collection, :provenance, :provider,
                   :sponsor, :genre, :format,:archival_item_identifier, :fonds_title, :fonds_creator,
                   :fonds_description, :fonds_identifier, :is_referenced_by, :date_digitized,
                   :transcript, :technical_note, :year]

    self.terms -= [:abstract, :access_right, :rights_notes, :bibliographic_citation]

    def self.required_fields
      [:title, :rights_statement, :provider]
    end

    def self.primary_terms
      [:title, :rights_statement, :provider, :license]
    end

    # The fields to render on a work's metadata form
    def self.secondary_terms
        terms - required_fields -
          [:files, :visibility_during_embargo, :embargo_release_date,
           :visibility_after_embargo, :visibility_during_lease,
           :lease_expiration_date, :visibility_after_lease, :visibility,
           :thumbnail_id, :representative_id, :ordered_member_ids, :license,
           :collection_ids, :in_works_ids, :admin_set_id, :rendering_ids,
           :member_of_collection_ids, :doi, :doi_status_when_public]
    end

    delegate :primary_terms, :secondary_terms, to: :class

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

  def rendering_ids
    to_param
  end

    private

    # @return [Array<FileSetPresenter>] presenters for the file sets in order of the ids
    def file_presenters
      @file_sets ||=
          Hyrax::PresenterFactory.build_for(ids: model.member_ids,
                                            presenter_class: VaultFileSetPresenter,
                                            presenter_args: current_ability)
    end

  end
end
