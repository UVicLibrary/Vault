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

    # Over-ride of Blacklight method, provide advanced constraints if needed,
    # otherwise call super.
    def render_constraints_filters(my_params = params)
      content = super(my_params)
      if advanced_query
        advanced_query.filters.each_pair do |field, value_list|
          label = facet_field_label(field)
          content << render_constraint_element(label,
                                               safe_join(Array(value_list), " <strong class='text-muted constraint-connector'>OR</strong> ".html_safe),
                                               :remove => search_action_path(remove_advanced_filter_group(field, my_params).except(:controller, :action))
          )
        end
      end

      content
    end

    # Override to fix double-rendering of constraints labels
    # ( 1. rendered by blacklight and 2. by blacklight advanced search)
    def render_constraint_element(label, value, options = {})
      Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'render_constraints_element is deprecated')
      return if value.include?("OR") && value.exclude?('text-muted constraint-connector')
      render(partial: "catalog/constraints_element", locals: { label: label, value: value, options: options })
    end

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