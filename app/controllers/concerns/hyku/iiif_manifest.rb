module Hyku
  # A controller mixin that provides a manifest action, which returns a
  # IIIF manifest for the presentation API
  # Included in controllers/hyrax/generic_works_controller
  module IIIFManifest
    extend ActiveSupport::Concern

    included do
      self.iiif_manifest_builder = Hyrax::CustomManifestBuilderService.new

      skip_load_and_authorize_resource only: :manifest
    end

     def manifest
       headers['Access-Control-Allow-Origin'] = '*'

       base_manifest = iiif_manifest_builder.manifest_for(presenter: iiif_manifest_presenter)

       json = base_manifest
       # For debugging
       # json = JSON.pretty_generate(base_manifest)

       respond_to do |wants|
         wants.json { render json: json }
         wants.html { render json: json }
       end
     end

    private

    def iiif_manifest_presenter
      Hyrax::CustomIiifManifestPresenter.new(search_result_document(id: params[:id])).tap do |p|
        p.hostname = request.base_url
        p.ability = current_ability
      end
    end

    def iiif_manifest_builder
      self.class.iiif_manifest_builder ||
          (Flipflop.cache_work_iiif_manifest? ? Hyrax::CachingIiifManifestBuilder.new : Hyrax::CustomManifestBuilderService.new)
    end

    def manifest_builder
      ::IIIFManifest::ManifestFactory.new(presenter)
    end
  end
end