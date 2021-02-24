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
    # @return [#can?]
    def ability
      @ability ||= NullAbility.new
    end

    ##
    # @return [String]
    def description
      Array(super).first || ''
    end

    ##
    # @return [Boolean]
    def file_set?
      model.try(:file_set?) || Array(model[:has_model_ssim]).include?('FileSet')
    end

    ##
    # @return [Array<DisplayImagePresenter>]
    def file_set_presenters
      member_presenters.select(&:file_set?)
    end

    ##
    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @todo should this use the simple_form i18n keys?! maybe the manifest
    #   needs its own?
    #
    # @return [Array<Hash{String => String}>] array of metadata hashes
    def manifest_metadata
      metadata_fields.each_with_object([]) do |field_name, array|
        unless get_metadata_value(field_name).blank?
          array << {
              'label' => field_name.to_s.humanize.capitalize.gsub(' label',''),
              'value' => get_metadata_value(field_name)
          }
        end
      end
    end

    def sequence_rendering
      Array(try(:member_ids)).map do |file_set_id|
        fsp = file_set_presenters.find { |p| p.id == file_set_id }
        next unless fsp

        { '@id' => Hyrax::Engine.routes.url_helpers.download_url(fsp.id, host: hostname),
          'format' => fsp.mime_type.present? ? fsp.mime_type : I18n.t("hyrax.manifest.unknown_mime_text"),
          'label' => (fsp.send(:title).first if fsp.send(:title).present? || '')
        }
      end.flatten
    end

    # Get the metadata value(s). Returns a string "foo" instead of ["foo"]
    def get_metadata_value(field)
      model.send(field).first
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
            .new(display_image_url(hostname),
                 format: 'jpg',
                 #format: image_format(alpha_channels),
                 width: width,
                 height: height,
                 iiif_endpoint: iiif_endpoint(latest_file_id, base_url: hostname))
      end

      def hostname
        @hostname || request.base_url # 'localhost'
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
        [:creator_label, :contributor_label, :subject_label, :publisher,
         :language, :identifier, :keyword, :date_created, :based_near_label,
         :related_url, :resource_type, :source, :rights_statement, :license,
         :extent, :alternative_title, :edition, :geographic_coverage_label,
         :coordinates, :chronological_coverage, :additional_physical_characteristics,
         :has_format, :physical_repository_label, :collection, :provenance,
         :provider_label, :sponsor, :genre_label, :format, :archival_item_identifier,
         :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier,
         :is_referenced_by, :date_digitized, :transcript, :technical_note, :year]
      else
        Hyrax::Forms::WorkForm.required_fields
      end
    end

  end
end