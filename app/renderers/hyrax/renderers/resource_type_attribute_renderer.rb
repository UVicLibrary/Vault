module Hyrax
  module Renderers
    class ResourceTypeAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          label = Hyrax::ResourceTypesService.label(value) rescue value
          link_to(label, search_path(value))
        end

        def search_path(value)
          Rails.application.routes.url_helpers.search_catalog_path(:"f[#{search_field}][]" => value)
        end

        def search_field
          ERB::Util.h(Solrizer.solr_name(options.fetch(:search_field, field), :facetable, type: :string))
        end
        
    end
  end
end
