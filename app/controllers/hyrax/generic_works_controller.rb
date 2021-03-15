module Hyrax
  class GenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks

    self.curation_concern_type = GenericWork

    def additional_response_formats(format)
      format.endnote do
        send_data(presenter.solr_document.export_as_endnote,
                  type: "application/x-endnote-refer",
                  filename: presenter.solr_document.endnote_filename)
      end
      format.ris do
        send_data(presenter.solr_document.export_as_ris(request),
                  type: "application/x-research-info-systems",
                  filename: presenter.solr_document.ris_filename)
      end
    end
  end
end
