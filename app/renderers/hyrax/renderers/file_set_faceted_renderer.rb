# frozen_string_literal: true
module Hyrax
  module Renderers
    class FileSetFacetedRenderer < FacetedAttributeRenderer

      # Note this is only used by views/hyrax/file_sets/attribute_rows.
      # If you're looking for a work's renderer for the keyword field, it
      # is in the Hyrax gem (renderers/hyrax/renderers/faceted_attribute_renderer).

      # Add filter for file sets to the link if we are on a file set page
      def search_path(value)
        Rails.application.routes.url_helpers.search_catalog_path(
            "f[#{search_field}][]": value,
            "f[has_model_ssim][]": "FileSet",
            locale: I18n.locale
        )
      end

    end
  end
end