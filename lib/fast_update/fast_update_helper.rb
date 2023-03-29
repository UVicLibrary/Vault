module FastUpdateHelper
  include Blacklight::RenderConstraintsHelperBehavior
  include Blacklight::FacetsHelperBehavior

  # Render cell in changes table
  # @param [FastUpdate::Change]
  def render_complete_cell(change)
    case change.complete
    when true
      if change.action == "replace"
        "<span class='label label-success'>Success</span>  #{change.count} replacement(s) made.".html_safe
      else
        "<span class='label label-success'>Success</span>".html_safe
      end
    when nil
      'No'
    when false
      '<span class="label label-danger">Error</span> Contact administrator for details.'.html_safe
    end
  end

  # Render the contents of "Fields containing URI" table cell in views/fast_update/changes/_list_works
  # @param [SolrDocument]
  # @param [String] - the uri to search for
  def render_field_names(document, uri)
    model = document[model_field_name].first
    field_names = solr_field_names[model].select { |field| document.has_key?(field) && document[field].include?(uri) }
    field_names.map { |field| desolrize(field) }.join(', ')
  end

  #== Override Blacklight Facets
  # See https://workshop.projectblacklight.org/v7.11.1/helper-method-overrides/
  ##
  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_facet_value(facet_field, item, options ={})
    path = path_for_facet(facet_field, item)
    content_tag(:span, :class => "facet-label") do
      link_to facet_display_value(facet_field, item), path, :class=>"facet_select", remote: true
    end + render_facet_count(item.hits)
  end

  # @param [String] - facet field name
  # @param [Blacklight::Solr::Response::Facets::FacetItem]
  def search_preview_path(facet_field, item)
    fast_update_search_preview_path(search_state.add_facet_params_and_redirect(facet_field, item))
  end

  #== Override Blacklight Constraints
  # See https://workshop.projectblacklight.org/v7.11.1/helper-method-overrides/
  ##
  # Render a single facet's constraint
  # @param [String] facet field
  # @param [Array<String>] values selected facet values
  # @param [Blacklight::SearchState] path query parameters
  # @return [String]
  def render_filter_element(facet, values, path)
    facet_config = facet_configuration_for_field(facet)

    safe_join(Array(values).map do |val|
      next if val.blank? # skip empty string
      render_constraint_element(facet_field_label(facet_config.key),
                                facet_display_value(facet, val),
                                remove: fast_update_search_preview_path(path.remove_facet_params(facet, val)),
                                classes: ["filter", "filter-" + facet.parameterize])
    end, "\n")
  end

  # Render a label/value constraint on the screen. Can be called
  # by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired,
  # although in most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # @param [String] label to display
  # @param [String] value to display
  # @param [Hash] options
  # @option options [String] :remove url to execute for a 'remove' action
  # @option options [Array<String>] :classes an array of classes to add to container span for constraint.
  # @return [String]
  def render_constraint_element(label, value, options = {})
    render(:partial => "fast_update/changes/constraints_element", :locals => {:label => label, :value => value, :options => options})
  end

  private

    def model_field_name
      "has_model_ssim"
    end

    def work_types
      Hyrax::QuickClassificationQuery.new(current_user).authorized_models
    end

  # @return [Hash] an array of solrized controlled property fields organized by work type
  # Example: { "GenericWork" => ["based_near_tesim",...] }. You can override this with your own hash
  # of models and field names
    def solr_field_names
      work_types.each_with_object({}) do |model, hash|
        hash[model.to_s] = model.controlled_properties.map { |prop| "#{prop}_tesim" }
      end
    end

  # Convert the solr field name into human-readable format for display
  # @param [String] - the solr field name, e.g. "based_near_tesim"
  # @return [String] - human-readable field name, e.g. "Based near"
    def desolrize(field)
      field.gsub('_tesim','').gsub('_',' ').capitalize
    end

  ##
  # Where should this facet link to?
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  # @return [String]
    def path_for_facet(facet_field, item)
      facet_config = facet_configuration_for_field(facet_field)
      if facet_config.url_method
        send(facet_config.url_method, facet_field, item)
      else
        fast_update_search_preview_path(search_state.add_facet_params_and_redirect(facet_field, item))
      end
    end

end