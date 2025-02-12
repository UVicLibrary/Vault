class VaultWorkShowPresenter < Hyku::WorkShowPresenter

    include Hyrax::DOI::DOIPresenterBehavior
    include Hyrax::DOI::DataCiteDOIPresenterBehavior

    attr_accessor :solr_document, :current_ability, :request

    class_attribute :collection_presenter_class
    class_attribute :iiif_metadata_fields

    self.collection_presenter_class = VaultCollectionPresenter
    self.presenter_factory_class = VaultMemberPresenterFactory

        # Methods used by blacklight helpers
    # delegate :has?, :first, :fetch, :export_formats, :export_as, to: :solr_document

    # delegate fields from Hyrax::Works::Metadata to solr_document
    delegate :provider_label, :creator_label, :based_near_label, :subject_label,
             :contributor_label, :physical_repository_label, :genre_label,
             :geographic_coverage, :genre, :related_url, :depositor, :identifier,
             :resource_type, :keyword, :itemtype, :admin_set, :geographic_coverage_label,
             :chronological_coverage, :thumbnail_path,
             to: :solr_document

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context. Used so
    #                                  the GraphExporter knows what URLs to draw.
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = Hyrax::SolrDocument::OrderedMembers.decorate(solr_document)
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    # delegate :stringify_keys, :human_readable_type, :collection?, :to_s,
    #          to: :solr_document

    # Metadata Methods
    delegate :title, :date_created, :description,
             :creator, :contributor, :subject, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :license, :source, :rights_statement, :thumbnail_id,
             :representative_id, :rendering_ids, :member_of_collection_ids, :technical_note,
             :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier,
             :is_referenced_by, :date_digitized, :technical_note, :year, :alternative_title,
             :edition, :coordinates, :choronological_coverage, :physical_repository,
             :additional_physical_characteristics, :has_format, :collection, :provenance,
             :sponsor, :format, :transcript, :archival_item_identifier,
             to: :solr_document

end