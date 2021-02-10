require 'iiif_manifest'

module Hyrax
  # This gets mixed into FileSetPresenter in order to create
  # a canvas on a IIIF manifest
  module DisplaysImage
    extend ActiveSupport::Concern

    # Creates a display image only where FileSet is an image.
    #
    # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
    # Fix error where Riiif holds onto earlier versions of an image
    # See https://github.com/samvera/hyrax/pull/3165
    def display_image
      return nil unless solr_document.image? && current_ability.can?(:read, solr_document)
      # @todo this is slow, find a better way (perhaps index iiif url):
      # original_file = ::FileSet.find(id).original_file
      # latest version = ::FileSet.find(id).files.first.versions.last.uri
      latest_version_id = ActiveFedora::Base.uri_to_id(::FileSet.find(id).latest_content_version.uri)

      url = Hyrax.config.iiif_image_url_builder.call(
          latest_version_id, # original_file.id,
          request.base_url,
          Hyrax.config.iiif_image_size_default, ""
      )
      # Passing empty string suppresses the "wrong number of arguments" error.
      # Hyrax.config says the last argument is _format but not what that's supposed to be.

      # @see https://github.com/samvera-labs/iiif_manifest
      IIIFManifest::DisplayImage.new(url,
                                     width: 640,
                                     height: 480,
                                     iiif_endpoint: iiif_endpoint(latest_version_id)) # iiif_endpoint(original_file.id)


    end

    private

    def iiif_endpoint(file_id)
      return unless Hyrax.config.iiif_image_server?
      IIIFManifest::IIIFEndpoint.new(
          Hyrax.config.iiif_info_url_builder.call(file_id, request.base_url),
          profile: Hyrax.config.iiif_image_compliance_level_uri
      )
    end
  end
end
