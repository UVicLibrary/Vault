# frozen_string_literal: true

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
  class FullMetadataIiifManifestPresenter < Hyrax::IiifManifestPresenter
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
        klass = model.file_set? ? DisplayImagePresenter : FullMetadataIiifManifestPresenter
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
              'label' => field_name.to_s.humanize,
              'value' => get_metadata_value(field_name)
          }
        end
      end
    end

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
      include CustomDisplaysImage

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
                 format: image_format(alpha_channels),
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

      def solr_document
        model
      end

      # IIIF metadata for inclusion in the manifest
      #  Called by the `iiif_manifest` gem to add metadata
      #
      # @return [Array] array of metadata hashes
      def manifest_metadata
        metadata = []
        metadata_fields.each do |field|
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

    end

    private

      def ordered_member_ids
          proxy_field = 'proxy_in_ssi'
          target_field = 'ordered_targets_ssim'
          Hyrax::SolrService
              .query("#{proxy_field}:#{self.id}", rows: 10_000, fl: target_field)
              .flat_map { |x| x.fetch(target_field, nil) }
              .compact
        end
      end

      # Get the metadata value(s). Returns a string "foo" instead of ["foo"]
      def get_metadata_value(field)
        model.try(field).first
      end
