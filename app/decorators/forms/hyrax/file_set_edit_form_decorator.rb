# frozen_string_literal: true

# OVERRIDE Hyrax 3.5 to use our custom metadata
Hyrax::Forms::FileSetEditForm.class_eval do

  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.terms += [:genre, :provider, :alternative_title, :geographic_coverage,
                 :coordinates, :chronological_coverage, :extent, :identifier,
                 :additional_physical_characteristics, :has_format, :format,
                 :physical_repository, :provenance, :provider, :sponsor, :genre,
                 :is_referenced_by, :date_digitized, :transcript, :technical_note]
  self.terms -= [:related_url]

  # Only required field should be :title
  def self.required_fields
    [:title]
  end
  # self.required_fields -= [:keyword, :license, :creator]

  # Fields that are automatically drawn on the page above the fold
  def self.primary_terms
    [:title, :description, :transcript]
  end

  # Fields that are automatically drawn on the page below the fold
  def self.secondary_terms
    terms - primary_terms -
        [:visibility_during_embargo, :embargo_release_date,
         :visibility_after_embargo, :visibility_during_lease,
         :lease_expiration_date, :visibility_after_lease, :visibility,
         :thumbnail_id, :representative_id, :ordered_member_ids,
         :collection_ids, :in_works_ids, :admin_set_id]
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
            genre_attributes: [:id, :_destroy],
            transcript: []
        }
    ]
  end

end