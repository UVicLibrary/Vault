module Hyrax
  module Renderers
    class DateCreatedRenderer < AttributeRenderer

      # Draw the table row for the attribute. Render values in chronological/alphabetical order
      def render
        markup = ''

        return markup if values.blank? && !options[:include_empty]
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        Array(values.sort).each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end
        markup << %(</ul></td></tr>)
        markup.html_safe
      end

    private

      def li_value(value)
        link_to(value, search_path)
      end

      # Converted into a year range rather than a text search.
      def search_path
        if options.fetch(:begin).present? and options.fetch(:end).present?
          Rails.application.routes.url_helpers.search_catalog_path + range_params_string(options.fetch(:begin), options.fetch(:end))
        else
          Rails.application.routes.url_helpers.search_catalog_path + "?range[year_range_isim][missing]=true"
        end
      end

      def range_params_string(first, last)
        "?range[year_range_isim][begin]=#{first}&range[year_range_isim][end]=#{last}"
      end

    end
  end
end