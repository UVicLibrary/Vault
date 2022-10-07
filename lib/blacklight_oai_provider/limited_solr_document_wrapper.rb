module BlacklightOaiProvider
  class LimitedSolrDocumentWrapper < SolrDocumentWrapper
    attr_reader :document_model, :timestamp_field, :solr_timestamp, :limit

    # This class adds an fl parameter to all searches for calls of type ListRecords. Without this fl param,
    # ListRecord calls would repeatedly crash the server when trying to pull in the full_text_tsi field for
    # a large number of items.

    private

      def conditions(options) # conditions/query derived from options
        query = @controller.search_builder.merge(sort: "#{solr_timestamp} asc", rows: record_limit, fl: fl_fields).query
        if options[:from].present? || options[:until].present?
          query.append_filter_query(
              "#{solr_timestamp}:[#{solr_date(options[:from])} TO #{solr_date(options[:until]).gsub('Z', '.999Z')}]"
          )
        end

        query.append_filter_query(@set.from_spec(options[:set])) if options[:set].present?
        query
      end

      # Unfortunately, Solr can't exclude a field from fl so we have to list all the ones we want.
      def fl_fields
        ::SolrDocument.field_semantics.values + [solr_timestamp, "id"]
      end

      # We want to get the number of works and collections. Since this changes dynamically, we prefer not to rely
      # on the configuration option.
      def record_limit
        if Settings.multitenancy.enabled?
          solr_url = Account.find_by(tenant: Apartment::Tenant.current).solr_endpoint.url
        else
          solr_url = Blacklight.connection_config['url']
        end

        solr = ::RSolr.connect url: solr_url
        response = solr.get 'select', params: {
            q: "*:*",
            fq: ["has_model_ssim:GenericWork OR has_model_ssim:Collection"],
            rows: 5000,
            fl: "id"
        }
        response['response']['numFound']
      end

  end
end
