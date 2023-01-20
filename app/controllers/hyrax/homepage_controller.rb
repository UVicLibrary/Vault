class Hyrax::HomepageController < ApplicationController
  # Adds Hydra behaviors into the application controller
  include Blacklight::SearchContext
  include Blacklight::SearchHelper
  include Blacklight::AccessControls::Catalog
  include BlacklightRangeLimit::ControllerOverride

  require 'will_paginate/array'

  # The search builder for finding recent documents
  # Override of Blacklight::RequestBuilders
  def search_builder_class
    Hyrax::HomepageSearchBuilder
    # CustomRangeLimitBuilder
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

    @collection_presenters = build_presenters(collections.sort_by(&:title), Hyrax::CollectionPresenter)
    @collection_card_presenters = @collection_presenters.slice(0,8)
    @collections_count = count_collections

    # Homepage facet links
    @year_range_values = build_year_range_facets(year_range_facets)
    @genre_facet_values = build_facets(genre_facets)
    @subject_facet_values = build_facets(subject_facets)
    @place_facet_values = build_facets(place_facets)
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
    build_presenters(works, VaultWorkShowPresenter)
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
    "date_uploaded_dtsi desc"
  end

  def genre_facets
    [  "diaries", "historical maps", "letters (correspondence)", "photographs", "periodicals", "serials (publications)", "sound recordings", "video recordings (physical artifacts)" ]
  end

  # An array of EDTF date strings (see EdtfDateService)
  def year_range_facets
    %w[ 14XX 15XX 16XX 17XX 18XX 19XX ]
  end

  def subject_facets
    ["Artists", "Authors", "Families", "Immigrants", "Indigenous peoples", "Literature", "Local history", "Military history", "Transgender"]
  end

  def place_facets
    ["British Columbia--Victoria", "British Columbia--Vancouver Island", "British Columbia", "Canada", "China", "England", "France", "Ireland", "Japan"]
  end

  def build_facets(arr)
    # hits: 0 since we don't care about displaying the hit count
    arr.map { |val| Blacklight::Solr::Response::Facets::FacetItem.new(value: val, hits: 0) }
  end

  def build_year_range_facets(arr)

    services = arr.map { |century| EdtfDateService.new(century) }

    new_array = []
    new_array.push(start_range_facet(services.first.year_range.first))

    services.each do |service|
      value = service.humanized
      begin_date = service.year_range.first
      end_date = service.year_range.last
      renderer = Hyrax::Renderers::DateCreatedRenderer.new(:date_created, [], { begin: begin_date, end: end_date})
      path = renderer.search_path
      new_array.push({ value => path })
    end

    new_array.push(end_range_facet(services.last.year_range.last + 1))
    new_array
  end

  def start_range_facet(year)
    value = EdtfDateService.new("../#{year}").humanized
    begin_date = helpers.range_results_endpoint("year_range_isim",:min).to_i
    end_date = year
    renderer = Hyrax::Renderers::DateCreatedRenderer.new(:date_created, [], { begin: begin_date, end: end_date})
    path = renderer.search_path
    { value => path }
  end

  def end_range_facet(year)
    value = EdtfDateService.new("#{year}/..").humanized
    begin_date = year
    end_date = Date.today.year
    renderer = Hyrax::Renderers::DateCreatedRenderer.new(:date_created, [], { begin: begin_date, end: end_date})
    path = renderer.search_path
    { value => path }
  end

end
