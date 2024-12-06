Rails.application.config.to_prepare do

  # Override blacklight_advanced_search v. 7.0
  #
  # Blacklight::SearchState returns string parameter keys ("f_inclusive") instead of
  # symbols (:f_inclusive) after calling #to_h, so we add #symbolize_keys any time
  # Blacklight::SearchState.new(params, blacklight_config).to_h is called.
  #
  # So much code to change a single line because there's no single override point. Sigh.


  BlacklightAdvancedSearch::QueryParser.class_eval do

    def initialize(params, config)
      @params = Blacklight::SearchState.new(params, config).to_h.symbolize_keys
      @config = config
    end

  end

  BlacklightAdvancedSearch::RenderConstraintsOverride.module_eval do

    def remove_advanced_filter_group(field, my_params = params)
      if (my_params[:f_inclusive])
        my_params = Blacklight::SearchState.new(params, blacklight_config).to_h.symbolize_keys
        my_params[:f_inclusive] = my_params[:f_inclusive].dup
        my_params[:f_inclusive].delete(field)

        my_params.delete :f_inclusive if my_params[:f_inclusive].empty?
      end
      my_params
    end

  end

  BlacklightAdvancedSearch::CatalogHelperOverride.module_eval do

    def remove_advanced_facet_param(field, value, my_params = params)
      my_params = Blacklight::SearchState.new(params, blacklight_config).to_h.symbolize_keys

      if (my_params[:f_inclusive] &&
          my_params[:f_inclusive][field] &&
          my_params[:f_inclusive][field].include?(value))

        my_params[:f_inclusive] = my_params[:f_inclusive].dup
        my_params[:f_inclusive][field] = my_params[:f_inclusive][field].dup
        my_params[:f_inclusive][field].delete(value)

        my_params[:f_inclusive].delete(field) if my_params[:f_inclusive][field].empty?

        my_params.delete(:f_inclusive) if my_params[:f_inclusive].empty?
      end

      my_params.delete_if do |key, _value|
        [:page, :id, :counter, :commit].include?(key)
      end

      my_params
    end

  end
end