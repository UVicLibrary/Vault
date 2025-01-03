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

  # @param [String] - facet field name
  # @param [Blacklight::Solr::Response::Facets::FacetItem]
  def search_preview_path(facet_field, item)
    fast_update_search_preview_path(search_state.add_facet_params_and_redirect(facet_field, item))
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

end