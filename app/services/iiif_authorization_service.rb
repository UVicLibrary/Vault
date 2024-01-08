class IIIFAuthorizationService < Hyrax::IIIFAuthorizationService
  # Modifies #file_set_id_for to decode the image URL.
  # Restricts access to IIIF image URLs to download
  # users/groups only (except for thumbnails).

  # Replaces Hyrax::IIIFAuthorizationService
  # in config/initializers/riiif.rb.
  # RIIIF gem docs on authorization:
  # https://github.com/sul-dlss/riiif#authorization

  private

  def file_set_id_for(object)
    URI.decode_www_form_component(object.id).to_s.split('/').first
  end

  # def thumbnail?
  #   @controller.params[:size] == IIIFThumbnailPaths::THUMBNAIL_SIZE ||
  #       @controller.params[:size] == LargeIIIFThumbnailPaths::LARGE_THUMBNAIL_SIZE
  # end
end
