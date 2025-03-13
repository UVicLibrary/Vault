Hyrax::IiifHelper.module_eval do
  # Override Hyrax 3.1 - Hyrax::IIIFHelper
  #
  # Toggles the download button based on:
  #   1. If current tenant is Vault, check whether the user has download permissions
  #   2. If tenant is not Vault, allow anyone who can read the work to download

  def iiif_viewer_display(work_presenter, locals = {})
    render iiif_viewer_display_partial(work_presenter),
           locals.merge(presenter: work_presenter)
  end

  def iiif_viewer_display_partial(work_presenter)
    'hyrax/base/iiif_viewers/' + work_presenter.iiif_viewer.to_s
  end

  # @param [VaultWorkShowPresenter or Hyrax::WorkShowPresenter]
  def universal_viewer_base_url(work_presenter)
    if request.base_url.include? "vault"
      if can?(:download, work_presenter.id)
        "/uv/uv.html"
      else
        "/uv/uv-no-download.html"
      end
    else
      "/uv/uv.html"
    end
  end

  # @param [VaultWorkShowPresenter or Hyrax::WorkShowPresenter]
  def universal_viewer_config_url(work_presenter)
    if request.base_url.include? "vault"
      if can?(:download, work_presenter.id)
        "/uv/uv-config.json"
      else
        "/uv/uv-config-no-download.json"
      end
    else
      "/uv/uv-config.json"
    end
  end

end