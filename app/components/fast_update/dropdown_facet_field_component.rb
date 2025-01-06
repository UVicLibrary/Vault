# frozen_string_literal: true
#
# Created for Blacklight v. 7.38 & Hyrax v.4.0
#
# This is here to tell the app to render
# components/fast_update/dropdown_facet_field_component.html.erb
# template instead of hyrax/dropdown_facet_field_component.html.erb.
#
module FastUpdate
  class DropdownFacetFieldComponent < Hyrax::DropdownFacetFieldComponent

    def facet_item_presenters
      return to_enum(:facet_item_presenters) unless block_given?

      @facet_field.paginator.items.each do |item|
        skipped = facet_config.skip_item&.call(item)

        yield facet_item_presenter(item) unless skipped

        item.items&.each do |subitem|
          yield facet_item_presenter(subitem.dup.tap { |i| i.fq = nil if skipped })
        end
      end
    end

    def facet_item_presenter(facet_item)
      config = facet_config(facet_item.field)

      (config.item_presenter || Blacklight::FacetItemPresenter).new(facet_item, config, helpers, facet_item.field)
    end

    def facet_config(key = nil)
      return @facet_field.facet_field if key.nil?
      helpers.blacklight_config.facet_fields[key]
    end

  end
end