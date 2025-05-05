module Hyrax
  class GenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    include Hyrax::DOI::TombstoneWorksControllerBehavior

    # Defined in the hydra-head gem
    # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
    include Hydra::Controller::IpBasedAbility

    self.curation_concern_type = GenericWork
    self.show_presenter = VaultWorkShowPresenter

    # Catch deleted work
    rescue_from Blacklight::Exceptions::RecordNotFound, Ldp::Gone, with: :not_found

    rescue_from ActionController::UnknownFormat do
      render status: 406, json: { response: 'Requested format (or blank format) is not supported.' }
    end

    after_action :export_files, only: :update

    def not_found
      # Sets alert to display once redirected page has loaded
      flash.alert = "The work you're looking for may have moved or does not exist. Try searching for it in the search bar."
      redirect_to help_path
      return
    end

    # Rescue error where bots shove collection ids into work URLs
    def build_breadcrumbs
      if action_name == 'show' && search_result_document(id: params[:id]).hydra_model != GenericWork
        render status: 404, json: { response: "No work with id #{params[:id]}" }
      else
        super
      end
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
          raise Blacklight::Exceptions::RecordNotFound unless @document && @curation_concern && @curation_concern.work?

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

    # Override to force Content-Type to 'application/json'
    # This may not be necessary after Rails > 6.1
    def manifest
      json = iiif_manifest_builder.manifest_for(presenter: iiif_manifest_presenter)

      respond_to do |format|
        format.any {
          response.headers['Content-Type'] = 'application/json;charset=utf-8'
          response.headers['Access-Control-Allow-Origin'] = '*'
          render json: json
        }
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

    def export_files
      if (curation_concern.create_date < 3.months.ago) && Rails.env.production?
        curation_concern.file_sets.each do |file_set|
          BatchExport::ExportFileJob.perform_later(file_set)
        end
      end
    end

  end
end
