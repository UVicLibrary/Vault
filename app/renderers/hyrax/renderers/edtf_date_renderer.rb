# frozen_string_literal: true
module Hyrax
  module Renderers
    class EdtfDateRenderer < AttributeRenderer

      def attribute_value_to_html(value)
        begin
          service = EdtfDateService.new(value)
          humanized_value = service.humanized
        rescue EdtfDateService::InvalidEdtfDateError
          humanized_value = value
        end

        if microdata_value_attributes(field).present?
          "<span#{html_attributes(microdata_value_attributes(field))}>#{li_value(humanized_value)}</span>"
        else
          li_value(humanized_value)
        end
      end

    end
  end
end