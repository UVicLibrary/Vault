require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/downloads_controller.rb')

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::DownloadsController.class_eval do

  protected

  # Customize the :read ability in your Ability class, or override this method.
  # Hydra::Ability#download_permissions can't be used in this case because it assumes
  # that files are in a LDP basic container, and thus, included in the asset's uri.
  def authorize_download!
    begin
      # Allow users to see thumbnails
      return if params[:file] == "thumbnail"
      if work_or_file_set_page?
        authorize! :show, params[asset_param_key]
      else
        authorize! :download, params[asset_param_key]
      end
    rescue CanCan::AccessDenied
      unauthorized_image = Rails.root.join("app", "assets", "images", "unauthorized.png")
      send_file unauthorized_image, status: :unauthorized
    end
  end

  def work_or_file_set_page?
    return false unless request.referer.presence
    referer = Addressable::URI.parse(request.referer).path
    accepted_paths.any? { |path| path == referer }
  end

  def accepted_paths
    [work_path, file_set_path, file_set_parent_path, pdf_viewer_path]
  end

  def pdf_viewer_path
    "#{Addressable::URI.parse(main_app.pdfjs_path).path}/full"
  end

  def work_path
    Addressable::URI.parse(main_app.polymorphic_path(asset.parent)).path
  end

  def file_set_parent_path
    Addressable::URI.parse(main_app.hyrax_parent_file_set_path(asset.parent, asset)).path
  end

  def file_set_path
    Addressable::URI.parse(main_app.polymorphic_path(asset)).path
  end

  # Overrides hydra-core/app/controllers/concerns/hydra/controller/download_behavior.rb
  # and, in later versions of Hyrax, Hyrax::StreamFileDownloadsControllerBehavior
  def prepare_file_headers
    super
    # Add/modify response headers to work with the pdfjs_viewer-rails gem
    prepare_pdf_file_headers if asset.pdf?
  end

  # We need to set specific headers to allow range requests from the
  # pdfjs viewer. Otherwise, response.headers['Content-Encoding']
  # would == 'gzip', which causes pdfjs to download the whole file
  # at once instead of requesting a content range. Also, Rack::Deflater
  # would erase the Content-Length header, which the viewer/browser
  # needs for range requests. See
  # https://github.com/rack/rack/blob/main/lib/rack/deflater.rb#L65
  def prepare_pdf_file_headers
    response.headers['Cache-Control'] = "no-transform"
    response.headers['Content-Encoding'] = "identity"
  end

end
