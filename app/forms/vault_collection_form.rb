# frozen_string_literal: true
class VaultCollectionForm < Hyrax::Forms::CollectionForm

  # Modified to add a custom field, :in_scua, as well as other/the
  # same fields as a GenericWorkForm

  delegate :in_scua, to: :model

  self.terms = [:in_scua,
                :resource_type,
                :title,
                :creator,
                :contributor,
                :description,
                :keyword,
                :license,
                :publisher,
                :date_created,
                :subject,
                :language,
                :representative_id,
                :thumbnail_id,
                :identifier,
                :based_near,
                :related_url,
                :visibility,
                :genre,
                :geographic_coverage,
                :collection_type_gid]


  def secondary_terms
    [
        :in_scua,
        :creator,
        :contributor,
        :keyword,
        :license,
        :publisher,
        :date_created,
        :subject,
        :genre,
        :geographic_coverage,
        :language,
        :identifier,
        :based_near,
        :related_url,
        :resource_type
    ]
  end

end