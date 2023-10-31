class IIIFAuthorizationService
  # Uses the AuthorizeByIpAddress module to authorize IIIF images for
  # the image viewer. This class replaces Hyrax::IIIFAuthorizationService
  # in the RIIIF configuration (config/initializers/riiif.rb). See also
  # the RIIIF gem docs on authorization:
  # https://github.com/sul-dlss/riiif#authorization

  attr_reader :controller
  def initialize(controller)
    @controller = controller
  end

  def can?(_action, object)
    # app/controllers/authorized_by_ip_address
    controller.authorized_by_ip?(document_for(object)) ||
        controller.current_ability.can?(:show, file_set_id_for(object))
  end

  private

  def file_set_id_for(object)
    URI.decode(object.id).split('/').first
  end

  # @param [RIIIF::Image] - Note object.id returns the image for the file,
  # NOT the file set. It looks something like foo%2Ffiles%2Ffoobar
  # @return [SolrDocument] - The document for the FileSet
  def document_for(object)
    SolrDocument.find(file_set_id_for(object))
  end
end
