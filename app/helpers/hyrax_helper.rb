module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior

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
    service = Hyrax::ResourceTypesService
    #console
    label = service.label(options) rescue options
    #to_sentence([options].map { |right| label = service.label(right) rescue right; link_to label, right })
  end
    
  def resource_type_index_links(options)
    service = Hyrax::ResourceTypesService
    if options[:document].resource_type.length > 0
      service.label(options[:document].resource_type.first) rescue options[:document].resource_type.first
    end
  end
  
end
