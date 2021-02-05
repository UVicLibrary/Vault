module Hyku
  class FileSetPresenter < Hyrax::FileSetPresenter
    # include DisplaysImage
    include Hyrax::DisplaysImage
    delegate :alternative_title, :geographic_coverage, :coordinates, :chronological_coverage, :extent, :additional_physical_characteristics, :has_format, :physical_repository, :provenance, :provider, :sponsor, :genre, :format, :is_referenced_by, :date_digitized, :transcript, :technical_note, :year, to: :solr_document
    # CurationConcern methods
    #delegate :rendering_ids, to: :solr_document




  end
end
