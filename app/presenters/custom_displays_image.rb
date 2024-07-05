# frozen_string_literal: true
require 'iiif_manifest'

# OVERRIDE Hyrax::DisplaysImage from Hyrax v. 3.5.0
# Changed "original_file" id to the latest file id that is
# ideally indexed to file set for faster performance. Fedora is a fallback.
# Fixes error where Riiif holds onto earlier versions of an image.
#
module CustomDisplaysImage
# This gets mixed into FileSetPresenter in order to create
# a canvas on a IIIF manifest
  extend ActiveSupport::Concern

  # Creates a display image only where FileSet is an image.
  #
  # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
  def display_image
    return nil unless solr_document.image? && current_ability.can?(:read, solr_document)
    return nil unless latest_file_id
    #  See https://github.com/samvera/hyrax/pull/3165 and
    # https://github.com/samvera/hyrax/pull/3764/commits/bb730aaf3367877ec2662e975aaa6208c7c60c7b#
    IIIFManifest::DisplayImage.new(display_image_url(request.base_url),
                                   width: width,
                                   height: height,
                                   iiif_endpoint: iiif_endpoint(latest_file_id))
  end

  private

    def display_image_url(base_url)
      Hyrax.config.iiif_image_url_builder.call(
          latest_file_id,
          base_url,
          Hyrax.config.iiif_image_size_default,
          format: image_format(alpha_channels)
      )
    end

    def iiif_endpoint(file_id, base_url: hostname)
      return unless Hyrax.config.iiif_image_server?
      IIIFManifest::IIIFEndpoint.new(
          Hyrax.config.iiif_info_url_builder.call(file_id, base_url),
          profile: Hyrax.config.iiif_image_compliance_level_uri
      )
    end

    def image_format(channels)
      channels&.include?('rgba') ? 'png' : 'jpg'
    end

  ##
  # @api private
  #
  # Get the id for the latest version of original file. If
  # `#original_file_id` is available on the object, simply use that value.
  # Otherwise, retrieve the original file directly from the datastore and
  # resolve the current version using `VersioningService`.
  #
  # The fallback lookup normally happens when a File Set was indexed prior
  # to the introduction of `#original_file_id` to the index document,
  # but is useful as a generalized failsafe to ensure we have done our best
  # to resolve the content.
  #
  # @note this method caches agressively. it's here to support IIIF
  #   manifest generation and we expect this object to exist only for
  #   the generation of a single manifest document. this insulates callers
  #   from the complex lookup behavior and protects against expensive and
  #   unnecessary database lookups.
    def latest_file_id
      @latest_file_id ||=
          begin
            result = current_file_version

            if result.blank?
              Rails.logger.warn "original_file_id for #{id} not found, falling back to Fedora."
              result = Hyrax::VersioningService.versioned_file_id ::FileSet.find(id).original_file
            end

            result
          end
    end
end