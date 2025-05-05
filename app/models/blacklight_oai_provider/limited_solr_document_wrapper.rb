module BlacklightOaiProvider
  class LimitedSolrDocumentWrapper < SolrDocumentWrapper

    # This class adds an fl parameter to all searches for calls of type
    # ListRecords. Without this fl param, ListRecord calls would repeatedly
    # crash the server when trying to pull in the full_text_tsi field for
    # a large number of items.

    # @return [Blacklight::Solr::Request]
    def conditions(constraints) # conditions/query derived from options
      super.tap do |query|
        query.merge("fl" => fl_fields)
      end
    end

    private

    # @return [Array] - the Solr field names/keys to include in the response
    # Unfortunately, Solr can't exclude a field using the fl parameter,
    # so we need to list all the ones we want instead.
    def fl_fields
      ::SolrDocument.field_semantics.values + [solr_timestamp, "id"]
    end

  end
end