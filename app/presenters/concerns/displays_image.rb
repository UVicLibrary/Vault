# This gets mixed into FileSetPresenter in order to create
# a canvas on a IIIF manifest
module DisplaysImage
  extend ActiveSupport::Concern

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
    url = display_image_url(request.base_url)
    IIIFManifest::DisplayImage.new(url,
                                   width: 640,
                                   height: 480,
                                   iiif_endpoint: iiif_endpoint(latest_file_id))
  end

  private

    def display_image_url(base_url)
      Hyrax.config.iiif_image_url_builder.call(
          latest_file_id,
          base_url,
          Hyrax.config.iiif_image_size_default,
          #format: image_format(alpha_channels)
          format: 'jpg'
      )
    end

     def base_image_url(file_id)
       Riiif::Engine.routes.url_helpers.info_url(file_id, host: request.base_url).sub(%r{/info\.json\Z}, '')
     end

    def iiif_endpoint(latest_file_id)
      IIIFManifest::IIIFEndpoint.new(base_image_url(latest_file_id), profile: "http://iiif.io/api/image/2/level2.json")
    end

    def unindexed_current_file_version
      # Rails.logger.warn "Indexed current_file_version for #{id} not found, falling back to Fedora."
      ActiveFedora::File.uri_to_id(::FileSet.find(id).current_content_version_uri)
    end

    def latest_file_id
      current_file_version || unindexed_current_file_version
    end
end
