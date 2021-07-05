module Hyrax
  module Renderers
    class GenreLabelRenderer < AttributeRenderer


      # Draw the table row for the attribute
      def render
        markup = ''

        return markup if values.none?(&:present?) && !options[:include_empty]
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        values_array = Array(values)
        if options.fetch(:genre_tesim) and options.fetch(:genre_tesim).include?("http://vocab.getty.edu/aat/300026096")
          values_array = values_array + ["exhibition catalogs"]
        end
        values_array.each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end
        markup << %(</ul></td></tr>)
        markup.html_safe
      end


      private

      def li_value(value)
        link_to(value, search_path(value))
      end

      def search_path(value)
        if value == "exhibition catalogs"
          Rails.application.routes.url_helpers.search_catalog_path(:"f[genre_sim][]" => value.gsub(" ","_"))
        else
          Rails.application.routes.url_helpers.search_catalog_path(:"f[#{field.to_s}_sim][]" => value)
        end
      end

    end
  end
end