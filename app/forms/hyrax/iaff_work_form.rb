# Generated via
#  `rails generate hyrax:work IaffWork`
module Hyrax
  # Generated form for IaffWork
  class IaffWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::IaffWork
    self.terms += [:provider, :genre, :geographic_coverage, :provenance, :type_of_resource, :coordinates, :gps_or_est, :year, :date_digitized, :technical_note]
    self.terms -= [:license, :source]
    self.required_fields += [:date_created, :description, :provider, :genre]
    self.required_fields -= [:keyword]
    
    def self.build_permitted_params
    	super + [
    			{
            resource_type_attributes: [:id, :_destroy],
            gps_or_est_attributes: [:id, :_destroy],
            genre_attributes: [:id, :_destroy]
          }
      ]
    end
    
    
  end
end
