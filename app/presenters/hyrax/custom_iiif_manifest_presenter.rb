# frozen_string_literal: true

module Hyrax
  ##
  # This presenter wraps objects in the interface required by `IIIFManifiest`.
  # It will accept either a Work-like resource or a SolrDocument.
  #
  # @example with a work
  #
  #   monograph = Monograph.new
  #   presenter = IiifManifestPresenter.new(monograph)
  #   presenter.title # => []
  #
  #   monograph.title = ['Comet in Moominland']
  #   presenter.title # => ['Comet in Moominland']

  #   This has been modified to show all Hyrax.config.iiif_manifest_fields (only required fields are the default)
  #
  # @see https://www.rubydoc.info/gems/iiif_manifest
  class CustomIiifManifestPresenter < IiifManifestPresenter
    delegate_all

    ##
    # @!attribute [w] ability
    #   @return [Ability]
    # @!attribute [w] hostname
    #   @return [String]
    attr_writer :ability, :hostname

    class << self
      ##
      # @param [Hyrax::Resource, SolrDocument]
      def for(model)
        klass = model.file_set? ? DisplayImagePresenter : CustomIiifManifestPresenter
        klass.new(model)
      end
    end

    ##
    # IIIF metadata for inclusion in the manifest
    # Called by the `iiif_manifest` gem to add metadata
    # https://github.com/samvera/iiif_manifest
    #
    # @return [Array<Hash{String => String}>] array of metadata hashes
    def manifest_metadata
      metadata_fields.each_with_object([]) do |field_name, array|
        unless get_metadata_value(field_name).blank?
          array << {
              'label' => field_name.to_s.humanize, #.capitalize.gsub(' label','')
              'value' => get_metadata_value(field_name)
          }
        end
      end
    end

    # This is optional and not including it seems to speed the viewer up by a few seconds
    #def sequence_rendering
    #  ordered_member_ids.map do |file_set_id|
    #    fsp = file_set_presenters.find { |p| p.id == file_set_id }
    #    next unless fsp
    #
    #    { '@id' => Hyrax::Engine.routes.url_helpers.download_url(fsp.id, host: hostname),
    #      'format' => fsp.mime_type.present? ? fsp.mime_type : I18n.t("hyrax.manifest.unknown_mime_text"),
    #      'label' => (model.title.first if model.title.present? || '')
    #    }
    #  end.flatten
    #end

    ##
    # @note cache member presenters to avoid querying repeatedly; we expect this
    #   presenter to live only as long as the request.
    #
    # @note skips presenters for objects the current `@ability` cannot read.
    #   the default ability has all permissions.
    #
    # @return [Array<IiifManifestPresenter>]
    def member_presenters
      @member_presenters_cache ||= Factory.build_for(ids: ordered_member_ids, presenter_class: self.class).map do |presenter|
        next unless ability.can?(:read, presenter.model)

        presenter.hostname = hostname
        presenter.ability  = ability
        presenter
      end.compact
    end

    class DisplayImagePresenter < Draper::Decorator
      delegate_all

      include Hyrax::DisplaysImage

      ##
      # @!attribute [w] ability
      #   @return [Ability]
      # @!attribute [w] hostname
      #   @return [String]
      attr_writer :ability, :hostname


      ##
      # Creates a display image only where #model is an image.
      #
      # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
      def display_image
        return nil unless model.image?
        return nil unless latest_file_id

        IIIFManifest::DisplayImage
            .new(display_image_url(@hostname),
                 format: 'jpg',
                 #format: image_format(alpha_channels),
                 width: width,
                 height: height,
                 iiif_endpoint: iiif_endpoint(latest_file_id))
      end

      def hostname
        @hostname || request.base_url
      end

      ##
      # @return [Boolean] false
      def work?
        false
      end
    end

    private

      # Expand this to include other fields besides the required fields (default)
      def metadata_fields
        if hostname.include?("vault")
           [:creator_label, :creator, :contributor_label, :contributor,
           :subject_label, :subject, :publisher, :language, :identifier,
           :keyword, :date_created, :based_near_label, :related_url,
           :resource_type, :source, :rights_statement, :license, :extent,
           :alternative_title, :edition, :geographic_coverage_label,
           :geographic_coverage, :coordinates, :chronological_coverage,
           :additional_physical_characteristics, :has_format, :physical_repository_label,
           :physical_repository, :collection, :provenance, :provider_label, :provider,
           :sponsor, :genre_label, :genre, :format, :archival_item_identifier,
           :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier,
           :is_referenced_by, :date_digitized, :transcript, :technical_note, :year]
        else
          Hyrax::Forms::WorkForm.required_fields
        end
      end

      def ordered_member_ids
        #solr = RSolr.connect url: Account.find_by(tenant: Apartment::Tenant.current).solr_endpoint.url
        solr = RSolr.connect url: Settings.solr.url
        response = solr.get 'select', params: {
            q: "proxy_in_ssi:#{self.id}",
            rows: 10_000,
            fl: "ordered_targets_ssim"
        }
        response['response']['docs'].first['ordered_targets_ssim']
      end

      # Get the metadata value(s). Returns a string "foo" instead of ["foo"]
      def get_metadata_value(field)
        model.try(field).first
      end

  end
end