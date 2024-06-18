module Hyrax
  class GenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks

    # Defined in the hydra-head gem
    # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
    include Hydra::Controller::IpBasedAbility

    self.curation_concern_type = GenericWork
    self.show_presenter = VaultWorkShowPresenter

    # Catch deleted work
    rescue_from Blacklight::Exceptions::RecordNotFound, Ldp::Gone, with: :not_found

    rescue_from ActionController::UnknownFormat do
      render json: { response: 'Requested format (or blank format) is not supported.', status: 406 }
    end

    def not_found
      # Sets alert to display once redirected page has loaded
      flash.alert = "The work you're looking for may have moved or does not exist. Try searching for it in the search bar."
      redirect_to help_path
      return
    end

    # Finds a solr document matching the id and sets @presenter
    # @raise CanCan::AccessDenied if the document is not found or the user doesn't have access to it.
    def show
      @user_collections = user_collections
      @document = search_result_document(id: params[:id])

      respond_to do |wants|
        wants.html {
          raise Blacklight::Exceptions::RecordNotFound unless @document
          # Authorizing based on the curation_concern currently fails
          authorize! :read, @document
          presenter && parent_presenter
        }
        wants.json do
          @curation_concern = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: params[:id])
          raise Blacklight::Exceptions::RecordNotFound unless @document && @curation_concern

          if can? :read, @document
            render :show, status: :ok
          else
            render status: :unauthorized, json: { error: "You are not authorized to access this resource." }
          end
        end
        additional_response_formats(wants)
        wants.ttl { render body: presenter.export_as_ttl, mime_type: Mime[:ttl] }
        wants.jsonld { render body: presenter.export_as_jsonld, mime_type: Mime[:jsonld] }
        wants.nt { render body: presenter.export_as_nt, mime_type: Mime[:nt] }
      end
    end

    private

    def set_default_response_format
      request.format = :html unless params[:format]
    end

    def additional_response_formats(format)
      format.endnote do
        send_data(presenter.solr_document.export_as_endnote,
                  type: "application/x-endnote-refer",
                  filename: presenter.solr_document.endnote_filename)
      end
    end

    def iiif_manifest_presenter
      # TO DO: Allow for caching of manifests. See Hyrax::CachingIiifManifestBuilder
      FullMetadataIiifManifestPresenter.new(search_result_document(id: params[:id])).tap do |p|
        p.hostname = request.base_url
        p.ability = current_ability
      end
    end

    # Use our custom manifest builders, which add file set metadata
    def iiif_manifest_builder
      self.class.iiif_manifest_builder ||
          (Flipflop.cache_work_iiif_manifest? ? Hyrax::CustomCachingIiifManifestBuilder.new : Hyrax::CustomManifestBuilderService.new)
    end

  end
end
