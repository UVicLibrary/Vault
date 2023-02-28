# frozen_string_literal: true
module Hyrax
  class FeaturedWorksController < ApplicationController

    def create
      presenter = VaultWorkShowPresenter.new(::SolrDocument.find(params["id"]), current_ability)
      authorize! :create, FeaturedWork
      @featured_work = FeaturedWork.new(work_id: params[:id])

      respond_to do |format|
        if @featured_work.save
          format.js { render 'reload_featured_button.js.erb', :locals => {presenter:presenter}}
        else
          format.json { render json: @featured_work.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      presenter = VaultWorkShowPresenter.new(::SolrDocument.find(params["id"]), current_ability)
      authorize! :destroy, FeaturedWork
      @featured_work = FeaturedWork.find_by(work_id: params[:id])
      @featured_work&.destroy

      respond_to do |format|
        format.js { render 'reload_featured_button.js.erb', :locals => {presenter:presenter}}
      end
    end

  end
end

