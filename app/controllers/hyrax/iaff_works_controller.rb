# Generated via
#  `rails generate hyrax:work IaffWork`
module Hyrax
  # Generated controller for IaffWork
  class IaffWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::IaffWork

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::IaffWorkPresenter
  end
end
