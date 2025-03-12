module Hyrax
  module DOI
    module TombstoneWorksControllerBehavior
      extend ActiveSupport::Concern
      # Controller override to redirect to Hyrax::DOI::TombstonesController
      # when deleting a work. Add this to your works controller like so:
      #
      # class GenericWorksController
      #    include Hyrax::DOI::TombstoneWorksControllerBehavior

      included do
        before_action :create_doi_tombstone, only: :destroy
      end

      def create_doi_tombstone
        curation_concern = search_result_document(id: params[:id])
        if curation_concern.doi.present? && ["findable","registered"].include?(curation_concern.doi_status_when_public)
          redirect_to main_app.new_hyrax_doi_tombstone_path(doi: curation_concern.doi, hyrax_id: params[:id])
        end
      end

    end
  end
end

