class VaultWorkShowPresenter < Hyku::WorkShowPresenter

    # app/controllers/authorize_by_ip_address.rb
    include AuthorizeByIpAddress

    include Hyrax::DOI::DOIPresenterBehavior
    include Hyrax::DOI::DataCiteDOIPresenterBehavior

    attr_accessor :solr_document, :current_ability, :request

    class_attribute :collection_presenter_class
    class_attribute :iiif_metadata_fields

    self.collection_presenter_class = VaultCollectionPresenter

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

    def downloadable?
      GenericWork.find(@solr_document.id).downloadable
    end

    private

    def authorized_item_ids(filter_unreadable: Flipflop.hide_private_items?)
      @member_item_list_ids ||=
          if filter_unreadable
            ordered_ids_with_visibility.reject do |hash|
              !current_ability.can?(:read, hash['id']) and !authorized_by_ip?(hash)
            end.pluck('id')
          else
            ordered_ids
          end
    end

    # Creates a hash with 'visibility_ssi' key needed for the AuthorizeByIpAddress module
    def ordered_ids_with_visibility
      ordered_ids.map do |id|
        { 'id' => id, 'visibility_ssi' => Hyrax::SolrService.search_by_id(id)['visibility_ssi'] }
      end
    end

    # @return [VaultFileSetPresenter]
    def member_presenter_factory
      Hyrax::MemberPresenterFactory.file_presenter_class = VaultFileSetPresenter
      @member_presenter_factory ||=
        Hyrax::MemberPresenterFactory.new(solr_document, current_ability, request)
    end

end
