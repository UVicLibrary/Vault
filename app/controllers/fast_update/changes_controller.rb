# frozen_string_literal: true
module FastUpdate
  class ChangesController < Hyrax::Dashboard::WorksController

    include HyraxHelper
    # Add  to config/application.rb:
    # config.autoload_paths << "#{root}/lib/fast_update"
    helper FastUpdateHelper

    helper_method :default_page_title, :admin_host?, :available_translations, :available_works, :collection_path

    # before_action do
    #   raise Hydra::AccessDenied unless current_user && current_ability.admin?
    # end

    before_action :authenticate

    configure_blacklight do |config|
      # Reset facet fields
      config.facet_fields = { }
      config.add_facet_field "member_of_collections_ssim", limit: 5, partial: 'facet_list', url_method: :search_preview_path
      config.search_builder_class = FastUpdate::UriSearchBuilder
    end


    def index
      # We render the 'new' form on the same page so we need to set variables here
      @change = FastUpdate::Change.new
      @changes = FastUpdate::Change.all.order(created_at: :desc)
    end

    def create
      # Filtering for empty strings allows model to validate arrays for presence of these attributes.
      # Otherwise [""].present? => true
      attributes = change_params.merge({ new_labels: new_labels.select(&:present?), new_uris: new_uris.select(&:present?) })

      # If a URI was pasted in, there may not be an old label set in params so we provide a dummy one.
      attributes["old_label"] == "" ? attributes['old_label'] = "No label available" : nil
      # Remove any whitespace from pasting uris in
      attributes['old_uri'] = attributes['old_uri'].strip

      @change = FastUpdate::Change.new(attributes)

      if @change.save
        # Enqueue the job
        collection = @change.collection_id == "all" ? nil : @change.collection_id
        ReplaceOrDeleteUriJob.perform_later(@change.id, collection)
        flash[:notice] = "Your files are being processed by #{view_context.application_name} in the background. You may need to refresh this page to see these updates."
      else
        flash[:error] = @change.errors.full_messages
      end
      # Redirect to here because we render everything on the index page
      redirect_to action: 'index'
    end

    def search_preview
      (@response, @document_list) = search_service.search_results
      respond_to do |format|
        format.js {
          render 'search_preview.js.erb', locals: { uri: params[:old_uri], label: params[:old_label] }
        }
      end
    end

    protected

    def default_page_title
      'Fast Maintenance'
    end

    private

    def authenticate
      # Can also be: authorize! :edit, available_work_types.first
      raise Hydra::AccessDenied unless current_user && current_ability.admin?
    end

    def available_work_types
      Hyrax::QuickClassificationQuery.new(current_user).authorized_models
    end

    def change_params
      params.require(:fast_update_change).permit(:old_uri, :old_label, :action, :collection_id)
    end

    def new_labels_and_uris
      params.require(:fast_update_change).permit(new_labels_and_uris: [:label, :uri])[:new_labels_and_uris]
    end

    def search_preview_params
      params.permit(:old_uri, :collection_id)
    end

    # Extracts labels from change parameters
    # @return [Array <Strings>]
    def new_labels
      new_labels_and_uris.values.map { |param| param[:label] }
    end

    # Extracts uris from change parameters
    # @return [Array <Strings>]
    def new_uris
      new_labels_and_uris.values.map { |param| param[:uri] }
    end

  end
end