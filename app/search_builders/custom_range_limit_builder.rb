class CustomRangeLimitBuilder < Hyrax::CatalogSearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder

  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]

  # If a user enters a search query but no sort, sort the results
  # by relevance (instead of "year_sort_dtsi title_sort_ssi asc",
  # which is used as the default for displaying works)
  ###
  # copy sorting params from BL app over to solr
  def add_sorting_to_solr(solr_params)
    if solr_params['q'].present? && solr_params['sort'].blank?
      solr_params['sort'] = 'score desc'
    else
      super
    end
  end

  # OVERRIDE Blacklight Advanced Search v.7
  # Delete facet field-specific limits that were overriding the
  # configured advanced search facet limit (-1)
  def facets_for_advanced_search_form(solr_params)
    super.tap do |solr_params|
      advanced_search_facet_config = blacklight_config.advanced_search[:form_solr_parameters]

      if blacklight_config.advanced_search[:form_solr_parameters] && advanced_search_facet_config.has_key?('facet.limit')
        solr_params['facet.field'].each do |field_key|
          solr_params.delete("f.#{field_key}.facet.limit")
        end
      end
    end
  end

  # If we are coming from a keyword facet, add file sets to the list
  # of allowed models
  def models
    if self.blacklight_params.try(:[], 'f').try(:[], 'has_model_ssim').try(:include?, "FileSet")
      super + [FileSet, Hyrax::FileSet]
    else
      super
    end
  end

  # OVERRIDE Hyrax 4.0: Delete the file sets only filter in order to
  # include all models (works, collections, file sets) in keyword search.
  def filter_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq].delete("{!term f=has_model_ssim}FileSet") if solr_parameters[:fq].include?("{!term f=has_model_ssim}FileSet")
    solr_parameters[:fq] << "{!terms f=has_model_ssim}#{models_to_solr_clause}"
  end

end