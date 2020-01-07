
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
    @featured_work_list = FeaturedWorkList.new
    @announcement_text = ContentBlock.for(:announcement)
    (@response, @works) = search_results(q: '', sort: sort_field, rows: 100) # Returns an array of 3 things. [0] is the solr response, [1] is an array of SolrDocuments
    # Sort works by date created, descending:
    # @works = @response[1].sort_by { |w| w.date_created }.reverse
    # @collections = @presenter.collections.sort_by{ |d| d.works.first.date_created }.paginate(:page => params[:collections_page], :per_page => 10)
    # Sort collections by alpha order:
    @collections = @presenter.collections.sort_by{ |d| d.title }.paginate(:page => params[:collections_page], :per_page => 10)
    @featured_collections = FeaturedCollection.all
    @featured_collection_list = FeaturedCollectionList.new

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
