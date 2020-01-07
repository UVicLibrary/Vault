module Hyrax
  # Provide select options for the license (dcterms:rights) field
  class LicenseService < QaSelectService
    def initialize
      super('rights_statements')
    end

#    def include_current_value(value, _index, render_options, html_options)
#      unless value.blank? || active?(value)
#        html_options[:class] << ' force-select'
#        render_options += [[label(value), value]]
#      end
#      [render_options, html_options]
#    end
  end
end
