# This gets mixed into FileSetPresenter in order to create
# a canvas on a IIIF manifest
module DisplaysImage
  extend ActiveSupport::Concern

  # Creates a display image only where FileSet is an image.
  #
  # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
  def display_image
    return nil unless solr_document.image? and current_ability.can?(:read, solr_document)
    # TODO: this is slow, find a better way (perhaps index iiif url):
    #  Changed "original_file" to the latest version id to
    #  fix error where Riiif holds onto earlier versions of an image
    #  See https://github.com/samvera/hyrax/pull/3165
    # original_file = FileSet.find(id).original_file
    latest_version_id = ActiveFedora::Base.uri_to_id(::FileSet.find(id).latest_content_version.uri)

    # TODO: We want url to be like https://libimages1.princeton.edu/loris/plum/0c%2F48%2F3j%2F48%2F8-intermediate_file.jp2/full/!200,200/0/default.jpg
    url = display_image_url(latest_version_id)
    IIIFManifest::DisplayImage.new(url, width: 640, height: 480, iiif_endpoint: iiif_endpoint(latest_version_id))
  end

  private

    def display_image_url(file_id, size = '600,')
      Riiif::Engine.routes.url_helpers.image_url(file_id,
                                                 host: request.base_url,
                                                 size: size)
    end

    def base_image_url(file_id)
      uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: request.base_url)
      # TODO: There should be a riiif route for this:
      uri.sub(%r{/info\.json\Z}, '')
    end

    def iiif_endpoint(file_id)
      IIIFManifest::IIIFEndpoint.new(base_image_url(file_id), profile: "http://iiif.io/api/image/2/level2.json")
    end
end
