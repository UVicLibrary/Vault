module Hyrax
  module IiifHelper
    def iiif_viewer_display(work_presenter, locals = {})
      render iiif_viewer_display_partial(work_presenter),
             locals.merge(presenter: work_presenter)
    end

    def iiif_viewer_display_partial(work_presenter)
      'hyrax/base/iiif_viewers/' + work_presenter.iiif_viewer.to_s
    end

    def universal_viewer_base_url(work_presenter)
      if request.base_url.include? "vault"
        if GenericWork.find(work_presenter.id).downloadable? or can?(:download, work_presenter.id)
          "#{request&.base_url}/uv/uv.html"
        else
          "#{request&.base_url}/uv/uv-no-download.html"
        end
      else
      "#{request&.base_url}/uv/uv.html"
      end
    end

    def universal_viewer_config_url(work_presenter)
      if request.base_url.include? "vault"
        if GenericWork.find(work_presenter.id).downloadable? or can?(:download, work_presenter.id)
          "#{request&.base_url}/uv/uv-config.json"
        else
          "#{request&.base_url}/uv/uv-config-no-download.json"
        end
      else
        "#{request&.base_url}/uv/uv-config.json"
      end

    end
  end
end