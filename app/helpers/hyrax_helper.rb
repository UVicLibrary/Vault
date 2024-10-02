module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior
  # Helpers provided by hyrax-doi plugin.
  include Hyrax::DOI::HelperBehavior

  def application_name
    Site.application_name || super
  end

  def institution_name
    Site.institution_name || super
  end

  def institution_name_full
    Site.institution_name_full || super
  end

  def banner_image
    Site.instance.banner_image? ? Site.instance.banner_image.url : super
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
