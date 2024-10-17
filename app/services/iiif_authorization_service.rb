# frozen_string_literal: true
class IIIFAuthorizationService < Hyrax::IiifAuthorizationService
  # Modifies #file_set_id_for to decode the image URL.
  # Restricts access to IIIF image URLs to download
  # users/groups only (except for thumbnails).

  # Replaces Hyrax::IIIFAuthorizationService
  # in config/initializers/riiif.rb.
  # RIIIF gem docs on authorization:
  # https://github.com/sul-dlss/riiif#authorization

  # @note we ignore the `action` param here in favor of the `:show` action for all permissions
  def can?(_action, object)
    # Allow all users to see thumbnails, like the downloads_controller
    return true if thumbnail?
    if uv_page?(controller.request)
      controller.current_ability.can?(:show, file_set_id_for(object))
    else
      controller.current_ability.can?(:download, file_set_id_for(object))
    end
  end

  private

  def file_set_id_for(object)
    URI.decode_www_form_component(object.id).to_s.split('/').first
  end

  def thumbnail?
    @controller.params[:size] == VaultThumbnailPathService.image_thumbnail_size ||
      @controller.params[:size] == CollectionThumbnailPathService.image_thumbnail_size ||
      # The size for thumbnails in search results view
      @controller.params[:size] == '!150,300' || @controller.params[:size] == '!300,300'
  end

  def uv_page?(request)
    return false unless request.referer.presence
    (Addressable::URI.parse(request.referer).path =~ /^\/uv\/uv(-no-download)?\.html/).present?
  end
end
