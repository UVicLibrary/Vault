module CustomCollectionBehavior
  PERMISSION_TEXT_VALUE_AUTHENTICATED = 'uvic'.freeze
  VISIBILITY_TEXT_VALUE_AUTHENTICATED = 'authenticated'.freeze

  # Use this query to get the ids of the member objects (since the containment
  # association has been flipped)
  def member_object_ids
    return [] unless id
    # This returns the wrong number of results. We could use ActiveFedora::Base.where
    # instead, but it is slower than searching Solr for large collections.
    # ActiveFedora::Base.search_with_conditions("member_of_collection_ids_ssim:#{id}").map(&:id)

    # Using RSolr instead:
    solr = RSolr.connect url: Blacklight.connection_config[:url]
    response = solr.get 'select', params: { q: "member_of_collection_ids_ssim:#{id}", rows: 10000 }
    # Returns an array of ids
    response['response']['docs'].map { |k,v| k['id'] }
  end

  # Destroy the related featured collection if there is one
  def destroy_featured
    FeaturedCollection.find_by!(collection_id: id).destroy
  rescue ActiveRecord::RecordNotFound
    true
  end

  # Override method in hydra-access-controls/app/models/concerns/hydra/access_controls/access_right.rb
  def authenticated_only_access?
    return false if open_access?
    self.visibility == "authenticated"
  end

  def authenticated_only?
    return false if open_access?
    has_permission_text_for?(PERMISSION_TEXT_VALUE_AUTHENTICATED) ||
        has_visibility_text_for?(VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end

end