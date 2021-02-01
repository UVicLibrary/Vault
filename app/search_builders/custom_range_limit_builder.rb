class CustomRangeLimitBuilder < Hyrax::CatalogSearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

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

end





