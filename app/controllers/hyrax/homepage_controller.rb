
class Hyrax::HomepageController < ApplicationController
  # Adds Hydra behaviors into the application controller
  include Blacklight::SearchContext
  include Blacklight::SearchHelper
  include Blacklight::AccessControls::Catalog

  require 'will_paginate/array'

  # The search builder for finding recent documents
  # Override of Blacklight::RequestBuilders
  def search_builder_class
    Hyrax::HomepageSearchBuilder
  end

  class_attribute :presenter_class
  self.presenter_class = Hyrax::HomepagePresenter

  layout 'homepage'
  helper Hyrax::ContentBlockHelper

  def index
    @presenter = presenter_class.new(current_ability, collections)
    @featured_researcher = ContentBlock.for(:researcher)
    @marketing_text = ContentBlock.for(:marketing)
    @announcement_text = ContentBlock.for(:announcement)

    # Featured collections
    @featured_collections = FeaturedCollection.all
    @featured_collection_list = FeaturedCollectionList.new
    # Featured works
    @featured_work_list = FeaturedWorkList.new
    # Recent collections
    sorted_collections = @presenter.collections.sort_by(&:create_date).reverse
    @recent_collection_presenters = Hyrax::PresenterFactory.build_for(ids: sorted_collections.pluck(:id),
                                      presenter_class: Hyrax::CollectionPresenter,
                                      presenter_args: nil).slice(0,6)
    # Recent works
    (@response, @works) = search_results(q: '', sort: sort_field, rows: 100) # Returns an array of 3 things. [0] is the solr response, [1] is an array of SolrDocuments
    @recent_work_presenters = Hyrax::PresenterFactory.build_for(ids: @works.pluck(:id),
                                                                presenter_class: Hyrax::WorkShowPresenter,
                                                                presenter_args: nil).slice(0,6)


    # For collections table, sort by alpha order:
    @collections = collections.sort_by(&:title).paginate(:page => params[:collections_page], :per_page => 10)

    recent
  end

  private

  # Return all collections
  def collections(rows: count_collections)
    builder = Hyrax::CollectionSearchBuilder.new(self)
                                            .rows(rows)
    response = repository.search(builder)
    response.documents
  rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
    []
  end

  def count_collections
    Collection.all.count
  end

    def recent
      # grab any recent documents
      (_, @recent_documents) = search_results(q: '', sort: sort_field, rows: 4)
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      @recent_documents = []
    end

    def sort_field
      # "#{Solrizer.solr_name('date_created_tesim', :stored_sortable, type: :string)} desc"
      "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc"
    end
end
