# OVERRIDE Blacklight v.7

Blacklight::Parameters.class_eval do

  # Our logs are blowing up with Blacklight deprecation warnings
  # about params like :utf8 and :locale that can and should be filtered
  # out harmlessly by Blacklight anyway. This patch prevents those warnings.
  #
  private

  def warn_about_deprecated_parameter_handling(params, permitted_params)
    diff = Hashdiff.diff(params.to_unsafe_h, params.permit(*permitted_params).to_h)

    return if diff.empty?

    # If diff only contains keys we want to ignore
    return if (diff.map { |_op, key, *| key } - ignored_params).empty?

    # If diff contains only facet params like f.genre_label_sim, f.year_sort_dtsim., etc.
    # These have changed to f[genre_label_sim][]= ... since Blacklight 7
    return if (diff.map { |_op, key, *| key } - ignored_params).all? { |key| key.start_with?('f.') }

    Deprecation.warn(Blacklight::Parameters, "Blacklight 8 will filter out non-search parameter, including: #{diff.map { |_op, key, *| key }.to_sentence}")
  end

  def ignored_params
    %W[utf8 locale id parent_id catalog range.year_range_isim.missing]
  end

end

Blacklight::FacetItemPresenter.class_eval do

  # The catalog/facet_limit parital eventually calls
  # search_state#add_facet_params_and_redirect , which calls
  # search_state#add_facet_params, which blows up our logs with
  # the warning "add_facet_params is deprecated..."

  # @private
  def add_href(path_options = {})
    if facet_config.url_method
      view_context.public_send(facet_config.url_method, facet_config.key, facet_item)
    else
      # view_context.search_action_path(search_state.add_facet_params_and_redirect(facet_config.key, facet_item).merge(path_options))
      view_context.search_action_path(
          search_state.filter(facet_config.key).add(facet_item)
              .to_h.with_indifferent_access.merge(path_options)
      )
    end
  end

end

# OVERRIDE Hyrax v.4.0 to silence deprecation warnings about
# scope.current_ability.
# WhY IS HyrAX RaiSInG DeprECAtioN WarNIngS OVeR UNmOdiFiEd mEtHOds
# ThAT iT CaLLs ITsELf
Hyrax::SearchService.class_eval do

  def method_missing(method_name, *arguments, &block)
    if scope&.respond_to?(method_name)
      if method_name != :current_ability
        Deprecation.warn(self.class, "Calling `#{method_name}` on scope " \
            'is deprecated and will be removed in Blacklight 8. Call #to_h first if you ' \
            ' need to use hash methods (or, preferably, use your own SearchState implementation)')
      end
      scope&.public_send(method_name, *arguments, &block)
    else
      super
    end
  end

end