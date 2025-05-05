# frozen_string_literal: true

# Created for Blacklight v. 7.38 & Hyrax v.4.0

# This replaces the default Blacklight::ConstraintLayoutComponent with
# a custom version that renders links with remote:true (see the html.erb template).
module FastUpdate
  class ConstraintComponent < Blacklight::ConstraintComponent

    def initialize(facet_item_presenter:, classes: 'filter', layout: FastUpdate::ConstraintLayoutComponent)
      @facet_item_presenter = facet_item_presenter
      @classes = classes
      @layout = layout
    end

  end
end