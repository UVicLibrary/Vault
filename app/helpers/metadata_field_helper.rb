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

  # A Blacklight index field helper_method
  # @param [Hash] options from blacklight helper_method invocation. Maps license URIs to links with labels.
  # @return [ActiveSupport::SafeBuffer] license links, html_safe
  def resource_type_links(options)
    to_sentence([options].map { |right| Hyrax::ResourceTypesService.label(right) })
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