require 'iiif_manifest'

# This gets mixed into FileSetPresenter in order to create
# a canvas on a IIIF manifest
module Hyrax::DisplaysImage
  extend ActiveSupport::Concern

  delegate :current_file_version, to: :solr_document

  # Creates a display image only where FileSet is an image.
  #
  # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
  def display_image
    return nil unless solr_document.image? and current_ability.can?(:read, solr_document)
    # Changed "original_file" id to the latest file id that is
    # ideally indexed to file set for faster performance. Fedora is a fallback.
    #  Fixes error where Riiif holds onto earlier versions of an image.
    #  See https://github.com/samvera/hyrax/pull/3165 and
    # https://github.com/samvera/hyrax/pull/3764/commits/bb730aaf3367877ec2662e975aaa6208c7c60c7b#
    url = display_image_url(hostname)
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
        # TO DO: Add support for png transparency
        #format: image_format(alpha_channels)
        format: 'jpg'
    )
  end

  def iiif_endpoint(latest_file_id)
    return unless Hyrax.config.iiif_image_server?
    IIIFManifest::IIIFEndpoint.new(
        # "#{_base_url}/images/#{ActionDispatch::Journey::Router::Utils.escape_segment(_file_id)}"
        Hyrax.config.iiif_info_url_builder.call(latest_file_id, hostname),
        profile: Hyrax.config.iiif_image_compliance_level_uri
    )
  end

  def unindexed_current_file_version
    # Rails.logger.warn "Indexed current_file_version for #{id} not found, falling back to Fedora."
    Hyrax::VersioningService.versioned_file_id FileSet.find(solr_document.id).original_file
  end

  def latest_file_id
    current_file_version || unindexed_current_file_version
  end

  def hostname
    @request.base_url || request.base_url
  end

end