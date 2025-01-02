module FastUpdate
  class FacetItemComponent < Blacklight::FacetItemComponent
    # Created for blacklight v.7.38

    ##
    # Overridden to add remote:true attribute to link_to. This sets the format to js,
    # which allows FastUpdate::ChangesController#search_preview to respond correctly.
    #
    # @return [String]
    # @private
    def render_facet_value
      tag.span(class: "facet-label") do
        link_to_unless(@suppress_link, label, href, class: "facet-select", rel: "nofollow", remote: true)
      end + render_facet_count
    end

  end
end