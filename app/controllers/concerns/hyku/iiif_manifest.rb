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

      json = base_manifest.to_json(pretty: true)

      respond_to do |wants|
        wants.json { render json: json }
        wants.html { render json: json }
      end
    end

    # def manifest
    #   headers['Access-Control-Allow-Origin'] = '*'
    #   base_manifest = JSON.parse(manifest_builder.to_h.to_json) # Manifest created by IIIF_Manifest gem
    #
    #   # Add file set data to the manifest. Work-level metadata is set in Hyku::FullMetadataWorkShowPresenter
    #   if request.base_url.include? "vault"
    #     manifest = IIIF::Service.parse(base_manifest)
    #     manifest.sequences.first.canvases.each do |canvas|
    #       fs_id = canvas["@id"].split('/').last
    #       doc = SolrDocument.find(fs_id)
    #       resource = canvas.images.first.resource
    #       # Add title and description
    #       resource.label = doc.title.first
    #       resource.description = doc.description.first
    #       # Add other metadata fields
    #       metadata_fields = Hyrax.config.iiif_metadata_fields
    #       metadata = metadata_fields.each_with_object([]) do |field, array|
    #         label = field.to_s.humanize.capitalize
    #         unless doc.send(field).blank?
    #           value = doc.send(field).first
    #           array.push(label => value)
    #         end
    #       end
    #       resource.metadata = metadata
    #     end
    #     json = manifest.to_json(pretty: true)
    #   else
    #     json = sanitize_manifest(base_manifest)
    #   end
    #
    #   respond_to do |wants|
    #     wants.json { render json: json }
    #     wants.html { render json: json }
    #   end
    # end

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