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
    self.iiif_manifest_builder = Hyrax::CustomManifestBuilderService.new

    # Catch deleted work
    rescue_from Blacklight::Exceptions::RecordNotFound, with: :not_found

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

    def edit
      build_form
      document = search_result_document(id: params[:id])
      # Used by views/records/vault/* partials to render field labels for URIs
      @all_labels = curation_concern.controlled_properties.each_with_object({}) do |prop, hash|
        labels = document.send("#{prop.to_s}_label")
        values = document.send(prop)

        hash["#{prop.to_s}_label"] = []
        values.each do |val|
          if val.include?("http")
            hash["#{prop.to_s}_label"].push({label: "#{labels[values.index(val)]}", uri: "#{val}" })
          elsif val.present?
            hash["#{prop.to_s}_label"].push({string: "#{labels[values.index(val)]}" })
          end
        end
      end
    end

    def update
      downloadable_to_boolean
      if actor.update(actor_environment)
        after_update_response
      else
        respond_to do |wants|
          wants.html do
            build_form
            render 'edit', locals: { document: ::SolrDocument.find(params[:id]) }, status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end
    end

    private

    def set_default_response_format
      request.format = :html unless params[:format]
    end

    def downloadable_to_boolean
      if params[:generic_work] && params[:generic_work][:downloadable].present?
        params[:generic_work][:downloadable] = ActiveModel::Type::Boolean.new.cast(params[:generic_work][:downloadable])
      end
    end

    def additional_response_formats(format)
      format.endnote do
        send_data(presenter.solr_document.export_as_endnote,
                  type: "application/x-endnote-refer",
                  filename: presenter.solr_document.endnote_filename)
      end
      format.ris do
        send_data(presenter.solr_document.export_as_ris(request),
                  type: "application/x-research-info-systems",
                  filename: presenter.solr_document.ris_filename)
      end
    end

    def iiif_manifest_presenter
      # TO DO: Allow for caching of manifests. See Hyrax::CachingIiifManifestBuilder
      FullMetadataIiifManifestPresenter.new(search_result_document(id: params[:id])).tap do |p|
        p.hostname = request.base_url
        p.ability = current_ability
      end
    end

    def iiif_manifest_builder
      self.class.iiif_manifest_builder ||
          (Flipflop.cache_work_iiif_manifest? ? Hyrax::CachingIiifManifestBuilder.new : Hyrax::CustomManifestBuilderService.new)
    end

  end
end
