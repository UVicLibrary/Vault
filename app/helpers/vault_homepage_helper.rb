module VaultHomepageHelper

  def search_or_homepage?
    request.base_url.include?("vault") &&
        (current_page?(root_path) || request.path.include?("catalog"))
  end

  # Render the collections that the current SolrDocument is in
  # @param []SolrDocument]: the document for a GenericWork
  # @return [HTML]: a <p> tag with collection links
  def render_card_collection_links(solr_doc)
    collection_list = Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
    return if collection_list.empty?
    links = collection_list.map { |collection| link_to(collection.title_or_label, hyrax.collection_path(collection.id), data: { turbolinks: false }) }
    array_of_links = []
    links.each_with_index do |link, n|
      array_of_links << link
      array_of_links << ', ' unless links[n + 1].nil?
    end
    tag.p safe_join([t('hyrax.collection.is_part_of'), ': '] + array_of_links), class: 'card-collection-link', tabindex: 0
  end

  # Renders a text list of collection titles with links
  # @param [Array]: an array of Hyrax::CollectionPresenters
  # @return [HTML]: markup for collection links separated by line breaks
  def render_collection_list(presenters)
    safe_join(collection_links(presenters.sort_by(&:title)), sanitize('<br/>'))
  end

  # @param [Array]: an array of Hyrax::CollectionPresenters
  # @return [Array]: an array of links
  def collection_links(presenters)
    presenters.map { |collection| link_to(collection.title_or_label, hyrax.collection_path(collection.id), data: { turbolinks: false }) }
  end

  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [String]: The name of the facet field, e.g. "genre_label_sim"
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_homepage_facet_value(facet_field, item, options ={})
    path = path_for_homepage_facet(facet_field, item)
    options[:label] ? label = options[:label] : label = facet_display_value(facet_field, item)
    content_tag(:li, class:"homepage-facet-label col-md") do
      link_to_unless(options[:suppress_link], label, path, class: "homepage-facet-link homepage-tab-link", data: { turbolinks: false })
    end
  end

  # Where should this facet link to?
  # @param [String] the facet field name, e.g. "genre_label_sim"
  # @param [String] item
  # @return [String]
  def path_for_homepage_facet(facet_field, item)
    facet_config = facet_configuration_for_field(facet_field)
    if facet_config.url_method
      send(facet_config.url_method, facet_field, item)
    else
      main_app.search_catalog_path(search_state.add_facet_params_and_redirect(facet_field, item))
    end
  end

  def label_for_homepage_facet(value)
    value.value.split(" (").first.titleize
  end

  def label_for_homepage_place_facet(value)
    # e.g. British Columbia--Victoria => Victoria, British Columbia--Vancouver Island => Vancouver Island
    if value.label.include?("British Columbia--")
      value.label.gsub("British Columbia--","")
    else
      label_for_homepage_facet(value)
    end
  end

  def render_year_range_value(hash)
    # byebug
    label = hash.keys.first
    path = hash[label]
    content_tag(:li, class:"homepage-facet-label col-md") do
      link_to(label, path, class: "homepage-facet-link homepage-tab-link", data: { turbolinks: false })
    end
  end


end
