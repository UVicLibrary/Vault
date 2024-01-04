require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/downloads_controller.rb')

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::DownloadsController.class_eval do

  # Customize the :read ability in your Ability class, or override this method.
  # Hydra::Ability#download_permissions can't be used in this case because it assumes
  # that files are in a LDP basic container, and thus, included in the asset's uri.
  def authorize_download!
    # Allow users to see thumbnails
    begin
      if params[:file] != "thumbnail"
        authorize! :download, params[asset_param_key]
      end
    rescue CanCan::AccessDenied
      unauthorized_image = Rails.root.join("app", "assets", "images", "unauthorized.png")
      send_file unauthorized_image, status: :unauthorized
    end
  end

end
