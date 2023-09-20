require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/collections_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::CollectionsController.class_eval do
  # Catch deleted collection
  rescue_from Ldp::Gone, ActiveFedora::ObjectNotFoundError, with: :not_found

  # The search builder to find the collections' members
  # inherits from Collections::CollectionMemberService
  self.membership_service_class = ::SortCollectionMembersByDateService

  # app/controllers/hyrax/google_map_behavior.rb
  include Hyrax::GoogleMapBehavior

  # You can override this method if you need to provide additional inputs to the search
  # builder. For example:
  #   search_field: 'all_fields'
  # @return <Hash> the inputs required for the collection member query service
  def params_for_query
    params.merge(q: params[:cq])
  end

  def show
    @curation_concern ||= Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: params[:id])
    presenter
    query_collection_members
    set_google_map_coordinates
  end

  def not_found
    # Sets alert to display once redirected page has loaded
    flash.alert = "The collection you're looking for may have moved or does not exist. Try searching for it in the search bar."
    redirect_to help_path
    return
  end
end
