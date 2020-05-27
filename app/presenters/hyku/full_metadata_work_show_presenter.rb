module Hyku
  class FullMetadataWorkShowPresenter < Hyku::ManifestEnabledWorkShowPresenter
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyku::FileSetPresenter

    delegate :resource_type, :alternative_title, :edition, :geographic_coverage, :coordinates, :chronological_coverage, :extent, :additional_physical_characteristics, :has_format, :physical_repository, :collection, :provenance, :provider, :sponsor, :genre, :archival_item_identifier, :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier, :is_referenced_by, :date_digitized, :transcript, :technical_note, :year, to: :solr_document
    #delegate :extent, :rendering_ids, to: :solr_document

    # A presenter that includes more iiif metadata fields than just
    # the required fields
    #
    # @return [Array] array of metadata hashes to include in the manifest
    # See https://github.com/samvera/iiif_manifest
    def manifest_metadata
      metadata = []
      metadata_fields.each_with_object(metadata) do |field|
        unless get_metadata_value(field).blank?
          metadata << {
                  'label' => field.to_s.humanize.capitalize,
                  'value' => get_metadata_value(field)
              }
        end
      end
      metadata
    end

    def downloadable?
      GenericWork.find(@solr_document.id).downloadable
    end

    private

    # Expand this to include other fields besides the required fields (default)
    def metadata_fields
      Hyrax.config.iiif_metadata_fields
    end

    # Get the metadata value(s). Returns a string "foo" instead of ["foo"]
    def get_metadata_value(field)
      self.solr_document.send(field).first
    end
  end
end
