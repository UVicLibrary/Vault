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
    @featured_work_list = FeaturedWorkList.new

    @recent_collection_presenters = recent_collection_presenters.slice(0,8)
    (@response, @works) = works_by_date_desc # Returns an array of 3 things. [0] is the solr response, [1] is an array of SolrDocuments
    @recent_work_presenters = recent_work_presenters.slice(0,8)
    @works_count = @works.count

    @collection_presenters = build_presenters(collections, Hyrax::CollectionPresenter).slice(0,8)
    @collections_count = count_collections
  end

  def more_recent_collections
    respond_to do |format|
      presenters = recent_collection_presenters.slice(params[:start].to_i, 8)
      format.js { render 'browse_collections/load_more.js.erb', locals: { presenters: presenters, append_to: params[:append_to] } }
    end
  end

  def more_recent_works
    respond_to do |format|
      presenters = recent_work_presenters.slice(params[:start].to_i, 8)
      format.js { render 'load_more_works.js.erb', locals: { presenters: presenters, append_to: params[:append_to] } }
    end
  end

  private

  def presenter
    @presenter ||= presenter_class.new(current_ability, collections)
  end

  def recent_collection_presenters
    build_presenters(collections_by_date_desc, Hyrax::CollectionPresenter)
  end

  def recent_work_presenters
    (response, works) = search_results(q: '', sort: sort_field, rows: 56)
    build_presenters(works, Hyrax::WorkShowPresenter)
  end

  def build_presenters(documents, presenter_class)
    Hyrax::PresenterFactory.build_for(ids: documents.pluck(:id),
                                      presenter_class: presenter_class,
                                      presenter_args: nil)
  end

  def collections_by_date_desc
    presenter.collections.sort_by(&:create_date).reverse
  end

  def works_by_date_desc
    search_results(q: '', sort: sort_field, rows: 48)
  end

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
    "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc"
  end
end
