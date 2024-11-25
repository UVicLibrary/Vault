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
                :based_near,
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
        :based_near,
        :resource_type
    ]
  end

  def self.permitted_params
    controlled_attributes = self.model_class.controlled_properties.each_with_object([]) do |property, array|
      array << { "#{property}_attributes".to_sym => [:id, :_destroy] }
    end
    super + controlled_attributes
  end

end