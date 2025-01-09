module MetadataFieldHelper

  def truncate_field_values(options)
    sanitize(to_sentence(options[:value]).truncate(275, separator: /\s/))
  end

  def extract_external_links(options)
    joined_values = safe_join(options[:value])
    urls = options[:value].map { |value| URI.extract(value) }
                          .flatten
                          .select { |url| url.start_with?("http") }
    urls.each { |url| joined_values.gsub!( url, create_link_to(url)) }
    sanitize(joined_values)
  end

  def create_link_to(url)
    '<a href="' + url + '">' + url + '</a>'
  end

  # Renders human-readable values for the Resource type facet by
  # fetching the label for the URI.
  # @param[Array or String] URI values for the Resource type facet
  # (e.g. "http://purl.org/dc/dcmitype/MovingImage" or
  # ["http://purl.org/dc/dcmitype/MovingImage"])
  def resource_type_values(values)
    # We need to wrap options in an array and flatten because options can
    # be an array when coming from Advanced Search
    to_sentence([values].flatten.map { |value| Hyrax::ResourceTypesService.label(value) })
  end

  def resource_type_index_links(options)
    service = Hyrax::ResourceTypesService
    if options[:document].resource_type.length > 0
      service.label(options[:document].resource_type.first) rescue options[:document].resource_type.first
    end
  end

  # A Blacklight index field helper_method
  # @param [Hash] options from blacklight helper_method invocation. Maps rights statement URIs to links with labels.
  # @return [ActiveSupport::SafeBuffer] rights statement links, html_safe
  def rights_statement_links(options)
    service = Hyrax.config.rights_statement_service_class.is_a?(Proc) ?
                  Hyrax.config.rights_statement_service_class.call.new :
                  Hyrax.config.rights_statement_service.new
    to_sentence(options[:value].map { |right| link_to service.label(right), right })
  end

end