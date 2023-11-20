class IIIFAuthorizationService
  # Modifies #file_set_id_for to decode the image URL.

  # This class replaces Hyrax::IIIFAuthorizationService
  # in the RIIIF configuration (config/initializers/riiif.rb). See also
  # the RIIIF gem docs on authorization:
  # https://github.com/sul-dlss/riiif#authorization

  attr_reader :controller
  def initialize(controller)
    @controller = controller
  end

  def can?(_action, object)
      controller.current_ability.can?(:read, file_set_id_for(object))
  end

  private

  def file_set_id_for(object)
    URI.decode(object.id).split('/').first
  end
  
end
