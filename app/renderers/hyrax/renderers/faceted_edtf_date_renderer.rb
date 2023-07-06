# frozen_string_literal: true
module Hyrax
  module Renderers
    class FacetedEdtfDateRenderer < FacetedAttributeRenderer

      # Instead of linking to a search for items with the same text value in date_created, this links to items with a
      # date_created value that falls within the date range of the currently viewed document/item. See
      # https://vault.library.uvic.ca/concern/generic_works/776d0e9a-5f27-4d7a-9259-a62425b0def7?locale=en
      # for an example

      def search_path(service, humanized_value)
        if service.nil? or unknown_or_no_date?(humanized_value)
          Rails.application.routes.url_helpers.search_catalog_path + "?range[year_range_isim][missing]=true"
        else
          first_year = service.first_year
          last_year = service.year_range.last
          Rails.application.routes.url_helpers.search_catalog_path + range_params_string(first_year, last_year)
        end
      end

      private

      def li_value(service, humanized_value)
        link_to(humanized_value, search_path(service, humanized_value))
      end

      def range_params_string(first_date, last_date)
        "?range[year_range_isim][begin]=#{first_date}&range[year_range_isim][end]=#{last_date}"
      end

      def attribute_value_to_html(value)
        begin
          service = EdtfDateService.new(value)
          humanized_value = service.humanized
        rescue EdtfDateService::InvalidEdtfDateError
          service = nil
          humanized_value = value
        end

        if microdata_value_attributes(field).present?
          "<span#{html_attributes(microdata_value_attributes(field))}>#{li_value(service, humanized_value)}</span>"
        else
          li_value(service, humanized_value)
        end
      end

      def unknown_or_no_date?(humanized_date)
        humanized_date == "unknown" or humanized_date == "no date"
      end

    end
  end
end