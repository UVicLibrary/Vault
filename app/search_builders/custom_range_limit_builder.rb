class CustomRangeLimitBuilder < Hyrax::CatalogSearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder

  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]

  # Method added to to fetch proper things for date ranges.
  def add_range_limit_params(solr_params)
    super.tap do |solr_params| # solr_params is the original result from BlacklightRangeLimit::RangeLimitBuilder
      # Optional: exclude Collections from results
      # if Account.find_by(tenant: Apartment::Tenant.current).name == "vault"
      #   solr_params[:fq] ||= []
      #   solr_params[:fq] << "has_model_ssim: GenericWork"
      # else
      #   solr_params[:fq] ||= []
      #   solr_params[:fq] << "has_model_ssim: IaffWork"
      # end
    end
  end

  # Another processing method, this one is NOT included in default processing chain,
  # it is specifically swapped in *instead of* add_range_limit_params for
  # certain ajax requests that only want to fetch range limit segments for
  # ONE field.
  #
  # It turns off faceting and sets rows to 0 as well, only results for
  # single specified field are needed.
  #
  # Specified field and parameters are specified in incoming parameters
  # range_field, range_start, range_end
  def fetch_specific_range_limit(solr_params)
    super.tap do |solr_params| # solr_params is the original result from BlacklightRangeLimit::RangeLimitBuilder
      # Optional: exclude admin sets from results
      # if Account.find_by(tenant: Apartment::Tenant.current).name == "vault"
      #   solr_params[:fq] ||= []
      #   solr_params[:fq] << "has_model_ssim: GenericWork"
      # else
      #   solr_params[:fq] ||= []
      #   solr_params[:fq] << "has_model_ssim: IaffWork"
      # end
    end
  end

  # A Solr param filter that is NOT included by default in the chain,
  # but is appended by AdvancedController#index, to do a search
  # for facets _ignoring_ the current query, we want the facets
  # as if the current query weren't there.
  #
  # Also adds any solr params set in blacklight_config.advanced_search[:form_solr_parameters]
  def facets_for_advanced_search_form(solr_p)
    # ensure empty query is all records, to fetch available facets on entire corpus
    solr_p["q"]            = '{!lucene}*:*'
    # explicitly use lucene defType since we are passing a lucene query above (and appears to be required for solr 7)
    solr_p["defType"]      = 'lucene'
    # We only care about facets, we don't need any rows.
    solr_p["rows"]         = "0"

    # Anything set in config as a literal
    if blacklight_config.advanced_search[:form_solr_parameters]
      solr_p.merge!(blacklight_config.advanced_search[:form_solr_parameters])
    end
  end

  # If we are coming from a keyword facet, add file sets to the list
  # of allowed models
  def models
    if self.blacklight_params.try(:[], 'f').try(:[], 'has_model_ssim').try(:include?, "FileSet")
      super + Hyrax::FileSetSearchBuilder.new("").send(:models)
    else
      super
    end
  end

end
