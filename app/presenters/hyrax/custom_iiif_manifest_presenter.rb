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
              'label' => field_name.to_s.humanize.capitalize,
              'value' => get_metadata_value(field_name)
          }
        end
      end
    end

    # Expand this to include other fields besides the required fields (default)
    def metadata_fields
      Hyrax.config.iiif_metadata_fields
    end

    # Get the metadata value(s). Returns a string "foo" instead of ["foo"]
    def get_metadata_value(field)
      model.send(field).first
    end

    class DisplayImagePresenter < Draper::Decorator
      delegate_all

      include DisplaysImage

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
        return nil unless current_file_version

        IIIFManifest::DisplayImage
            .new(display_image_url(hostname),
                 format: 'jpg',
                 #format: image_format(alpha_channels),
                 width: width,
                 height: height,
                 iiif_endpoint: iiif_endpoint(current_file_version, base_url: hostname))
      end

      def hostname
        @hostname || 'localhost'
      end

      ##
      # @return [Boolean] false
      def work?
        false
      end
    end

    private

    def metadata_fields
      Hyrax.config.iiif_metadata_fields
    end

  end
end