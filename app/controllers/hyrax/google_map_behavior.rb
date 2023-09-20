module Hyrax
  module GoogleMapBehavior
    def set_google_map_coordinates
      @google_map_response = google_map_collection_member_service.available_member_works
      @coordinates = @google_map_response.documents
    end

    def google_map_collection_member_service
      @gm_collection_member_service = GoogleMapCollectionMembersService.new(scope: self, collection: collection, params: params_for_query)
    end
  end
end