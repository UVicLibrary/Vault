class IIIFAuthorizationService < Hyrax::IIIFAuthorizationService
  # Modifies #file_set_id_for to decode the image URL.
  # Restricts access to IIIF image URLs to download
  # users/groups only (except for thumbnails).

  # Replaces Hyrax::IIIFAuthorizationService
  # in config/initializers/riiif.rb.
  # RIIIF gem docs on authorization:
  # https://github.com/sul-dlss/riiif#authorization

  attr_reader :controller
  def initialize(controller)
    @controller = controller
  end

  def can?(_action, object)
    if image_path? && !thumbnail?
      @controller.current_ability.can?(:download, file_set_id_for(object))
    else
      @controller.current_ability.can?(:show, file_set_id_for(object))
    end
  end

  private

  def file_set_id_for(object)
    URI.decode(object.id).split('/').first
  end

  def image_path?
    @controller.instance_of?(Riiif::ImagesController) &&
        @controller.action_name == "show"
  end

  def thumbnail?
    @controller.params[:size] == IIIFThumbnailPaths::THUMBNAIL_SIZE ||
        @controller.params[:size] == LargeIIIFThumbnailPaths::LARGE_THUMBNAIL_SIZE
  end
end
