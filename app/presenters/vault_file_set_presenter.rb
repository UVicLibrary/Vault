class VaultFileSetPresenter < Hyrax::FileSetPresenter
    include Hyrax::ModelProxy
    include Hyrax::PresentsAttributes
    include Hyrax::CharacterizationBehavior
    include Hyrax::WithEvents
    include CustomDisplaysImage

    attr_accessor :solr_document, :current_ability, :request

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # Extra Metadata Methods
    delegate :provider_label, :creator_label, :subject_label, :contributor_label,
             :physical_repository_label, :genre_label, :geographic_coverage_label, to: :solr_document

    delegate :alternative_title, :geographic_coverage, :coordinates, :chronological_coverage, :extent,
             :additional_physical_characteristics, :has_format, :physical_repository, :provenance,
             :provider, :sponsor, :genre, :format, :is_referenced_by, :date_digitized, :transcript,
             :technical_note, :year, to: :solr_document

    # Needed for CustomDisplaysImage
    delegate :current_file_version, to: :solr_document

    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @return [Array] array of metadata hashes
    def manifest_metadata
      metadata = []
      iiif_metadata_fields.each do |field|
        # This line catches empty strings in the creator field [""]
        next if Array.wrap(solr_document.public_send(field)).blank?
        # Use .public_send because .send raises ArgumentError due to namespace collision
        # https://bugs.ruby-lang.org/issues/12136
        metadata << {
            'label' => "#{field.to_s.capitalize.gsub('_', ' ')}",
            'value' => Array.wrap(solr_document.public_send(field))
        }
      end
      metadata
    end



    private

      def fetch_parent_presenter
        ids = Hyrax::SolrService.query("{!field f=member_ids_ssim}#{id}", fl: Hyrax.config.id_field, rows: 1)
                  .map { |x| x.fetch(Hyrax.config.id_field) }
        Hyrax.logger.warn("Couldn't find a parent work for FileSet: #{id}.") if ids.empty?
        ids.each do |id|
          doc = ::SolrDocument.find(id)
          next if current_ability.can?(:edit, doc)
          raise WorkflowAuthorizationException if doc.suppressed? && current_ability.can?(:read, doc)
        end
        Hyrax::PresenterFactory.build_for(ids: ids,
                                          presenter_class: VaultWorkShowPresenter,
                                          presenter_args: current_ability).first
      end

end