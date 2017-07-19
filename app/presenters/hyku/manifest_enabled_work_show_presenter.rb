module Hyku
  class ManifestEnabledWorkShowPresenter < Hyrax::WorkShowPresenter
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyku::FileSetPresenter


    delegate :resource_type, :alternative_title, :edition, :geographic_coverage, :coordinates, :chronological_coverage, :extent, :additional_physical_characteristics, :has_format, :physical_repository, :collection, :provenance, :provider, :sponsor, :genre, :archival_item_identifier, :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier, :is_referenced_by, :date_digitized, :transcript, :technical_note, :year, to: :solr_document

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    private

      def manifest_helper
        @manifest_helper ||= ManifestHelper.new(request.base_url)
      end
  end
end
