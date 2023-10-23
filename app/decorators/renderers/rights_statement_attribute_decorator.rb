# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::Renderers::RightsStatementAttributeRenderer.class_eval do

  ##
  # Special treatment for license/rights.  A URL from the Hyrax gem's config/hyrax.rb is stored in the descMetadata of the
  # curation_concern.  If that URL is valid in form, then it is used as a link.  If it is not valid, it is used as plain text.
  #
  # Changed Hyrax.config.rights_statement_service_class to Hyrax.config.rights_statement_service_class.call
  # to allow for per-tenant configuration
  def attribute_value_to_html(value)
    begin
      parsed_uri = URI.parse(value)
    rescue URI::InvalidURIError
      nil
    end
    if parsed_uri.nil?
      ERB::Util.h(value)
    else
      service_class = Hyrax.config.rights_statement_service_class.is_a?(Proc) ?
        Hyrax.config.rights_statement_service_class.call :
        Hyrax.config.rights_statement_service

      label = service_class.new.label(value) { value }
      %(<a href=#{ERB::Util.h(value)} target="_blank">#{label}</a>)
    end
  end

end
