module FastUpdate
  class UriSearchBuilder < Hyrax::WorksSearchBuilder

    self.default_processor_chain += [:filter_by_uri]

    def filter_by_uri(solr_parameters)
      solr_parameters[:fq] << uri_filter_query(@blacklight_params[:old_uri])
    end

    def uri_filter_query(uri)
      # Leave label blank since we only care about the uri right now
      pairs = LinkedDataSearchService.new('',uri).send(:uri_filters).map { |pair| "#{pair[0]}:\"#{pair[1]}\"" }
      pairs.join(" OR ")
    end

    def add_sorting_to_solr(solr_parameters)
      solr_parameters[:sort] ||= "title_sort_ssi asc"
    end

    # Allow non-work models
    # def only_works?
    #   false
    # end

  end
end

