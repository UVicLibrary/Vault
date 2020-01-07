module Hyrax
  class FeaturedCollectionListsController < ApplicationController
    def create
      authorize! :update, FeaturedCollection
      FeaturedCollectionList.new.featured_collections_attributes = list_params[:featured_collections_attributes]
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :no_content }
      end
    end

    def collection_presenters
      ability = nil
      Hyrax::PresenterFactory.build_for(ids: ids,
                                        presenter_class: Hyrax::CollectionShowPresenter,
                                        presenter_args: ability)
    end

    private

      def list_params
        params.require(:featured_collection_list).permit(featured_collections_attributes: [:id, :order])
      end
  end
end
