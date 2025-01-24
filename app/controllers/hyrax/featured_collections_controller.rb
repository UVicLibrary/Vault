module Hyrax
  class FeaturedCollectionsController < ApplicationController

    def create
      authorize! :create, FeaturedCollection
      @featured_collection = FeaturedCollection.new(collection_id: params[:collection_id])

      respond_to do |format|
        if @featured_collection.save
          format.json {
            render json: @featured_collection, status: :created
          }
        else
          format.json { render json: @featured_collection.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize! :destroy, FeaturedCollection
      @featured_collection = FeaturedCollection.find_by(collection_id: params[:collection_id])
      @featured_collection&.destroy

      respond_to do |format|
        format.json { head :no_content }
      end
    end

    # Similar to the "create" command, "index" handles the response as a redirect_to statement as opposed
    # to a render statement
    def index
      authorize! :create, FeaturedCollection
      @featured_collection = FeaturedCollection.new(collection_id: params[:collection_id])

      respond_to do |format|
        if @featured_collection.save
          format.json {
            redirect_to dashboard_collection_path(id: params[:collection_id], format: 'html')
          }
        else
          format.json { render json: @featured_collection.errors, status: :unprocessable_entity }
        end
      end
    end

    # Similar to the "destroy" command, "show" handles the response as a redirect_to as opposed
    # to a json response
    def show
      authorize! :destroy, FeaturedCollection
      @featured_collection = FeaturedCollection.find_by(collection_id: params[:collection_id])
      @featured_collection&.destroy

      redirect_to dashboard_collection_path(id: params[:collection_id], format: 'html')
    end

  end
end
