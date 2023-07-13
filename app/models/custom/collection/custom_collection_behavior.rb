module CustomCollectionBehavior
  PERMISSION_TEXT_VALUE_AUTHENTICATED = 'uvic'.freeze
  VISIBILITY_TEXT_VALUE_AUTHENTICATED = 'authenticated'.freeze

  # Compute the sum of each file in the collection using Solr to
  # avoid having to access Fedora. This was deprecated in main Hyrax
  #
  # @return [Fixnum] size of collection in bytes
  # @raise [RuntimeError] unsaved record does not exist in solr
  def bytes
    return 0 if member_object_ids.empty?

    raise "Collection must be saved to query for bytes" if new_record?

    # One query per member_id because Solr is not a relational database
    member_object_ids.collect { |work_id| size_for_work(work_id) }.sum
  end

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

  # Calculate the size of all the files in the work
  # @param work_id [String] identifer for a work
  # @return [Integer] the size in bytes
  def size_for_work(work_id)
    argz = { fl: "id, #{file_size_field}",
             fq: "{!join from=#{member_ids_field} to=id}id:#{work_id}" }
    files = ::FileSet.search_with_conditions({}, argz)
    files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
  end

  # Field name to look up when locating the size of each file in Solr.
  # Override for your own installation if using something different
  def file_size_field
    "file_size_lts"
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

  # @return [Array <Integer>] - [number of downloadable works, number of total works]
  def count_downloadable
    works = GenericWork.where(member_of_collection_ids_ssim: self.id)
    [ works.select(&:downloadable).count, works.count ]
  end

  def authenticated_only?
    return false if open_access?
    has_permission_text_for?(PERMISSION_TEXT_VALUE_AUTHENTICATED) ||
        has_visibility_text_for?(VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end

end