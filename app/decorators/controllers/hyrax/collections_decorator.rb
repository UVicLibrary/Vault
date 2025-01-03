require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/collections_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::CollectionsController.class_eval do
  # Catch deleted collection
  rescue_from Ldp::Gone, ActiveFedora::ObjectNotFoundError, Blacklight::Exceptions::RecordNotFound, with: :not_found

  rescue_from ActionController::UnknownFormat do
    render json: { response: 'Requested format (or blank format) is not supported.', status: 406 }
  end

  # The search builder to find the collections' members
  # inherits from Collections::CollectionMemberService
  self.membership_service_class = ::NestedWorksSearchService

  self.presenter_class = ->() {
    if Account.find_by(tenant: Apartment::Tenant.current).try(:name).try(:include?, "vault")
      VaultCollectionPresenter
    else
      Hyrax::CollectionPresenter
    end
  }

  # app/controllers/hyrax/google_map_behavior.rb
  include Hyrax::GoogleMapBehavior

  # Defined in the hydra-head gem
  # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
  include Hydra::Controller::IpBasedAbility

  # You can override this method if you need to provide additional inputs to the search
  # builder. For example:
  #   search_field: 'all_fields'
  # @return <Hash> the inputs required for the collection member query service
  def params_for_query
    params.merge(q: params[:cq], search_field: 'all_fields')
  end

  def show
    @curation_concern = @collection # we must populate curation_concern
    authorize! :read, curation_concern
    presenter
    query_collection_members
    set_google_map_coordinates if presenter_class.call == VaultCollectionPresenter
  end

  def presenter
    @presenter ||= begin
                     presenter_class.call.new(curation_concern, current_ability)
                   end
  end

  def not_found
    # Sets alert to display once redirected page has loaded
    flash.alert = "The collection you're looking for may have moved or does not exist. Try searching for it in the search bar."
    redirect_to help_path
    return
  end
end
