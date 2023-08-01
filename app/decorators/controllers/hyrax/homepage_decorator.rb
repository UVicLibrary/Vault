require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/homepage_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::HomepageController.class_eval do
  # Required for "Time period" facets
  include RangeLimitHelper

  def index
    @presenter = presenter_class.new(current_ability, collections)
    @featured_researcher = ContentBlock.for(:researcher)
    @marketing_text = ContentBlock.for(:marketing)
    @featured_work_list = FeaturedWorkList.new
    @announcement_text = ContentBlock.for(:announcement)


    if request.base_url.include? "vault"
      @featured_collection_list = FeaturedCollectionList.new

      # Homepage facet links are configured via VaultHomepageHelper
      # Used by the "List All" list of collections
      @collection_list_presenters = build_presenters(presenter.collections.sort_by(&:title), Hyrax::CollectionPresenter)
      # Used by the All Collections tab
      @collection_card_presenters = @collection_list_presenters.slice(0,8)
      # Used by the Recent Collections tab
      @recent_collection_presenters = build_presenters(get_recent_collections(0), Hyrax::CollectionPresenter)

      # @response is used by the homepage "Time period" facet
      # The other instance variables are used by the Recent Works tab
      @response, @recent_works = works_search_service.search_results
      @recent_work_presenters = build_presenters(@recent_works, VaultWorkShowPresenter)
      @work_count = @response['response']['numFound']
    else
      recent
    end
  end

  def more_recent_collections
    respond_to do |format|
      presenters = build_presenters(get_recent_collections(params[:start].to_i), Hyrax::CollectionPresenter)
      format.js { render 'browse_collections/load_more.js.erb', locals: { presenters: presenters, append_to: params[:append_to] } }
    end
  end

  def more_recent_works
    respond_to do |format|
      presenters = build_presenters(get_recent_works(params[:start].to_i), VaultWorkShowPresenter)
      format.js { render 'load_more_works.js.erb', locals: { presenters: presenters, append_to: params[:append_to] } }
    end
  end

  private

  def presenter
    @presenter ||= presenter_class.new(current_ability, collections)
  end

  def get_recent_collections(start)
    @recent_collections ||= presenter.collections.sort_by(&:create_date).reverse
    @recent_collections.slice(start,8)
  end

  def build_presenters(documents, presenter_class)
    Hyrax::PresenterFactory.build_for(ids: documents.pluck(:id),
                                      presenter_class: presenter_class,
                                      presenter_args: nil)
  end

  def get_recent_works(start)
    works_search_service.search_results do |builder|
      builder.start(start)
    end[1]
  end

  def works_search_service
    Hyrax::SearchService.new(config: blacklight_config,
                             user_params: { q: '', sort: sort_field, rows: 8 },
                             scope: self,
                             search_builder_class: Hyrax::WorksSearchBuilder)
  end

  # Return all collections
  def collections(rows: count_collections)
    Hyrax::CollectionsService.new(self).search_results do |builder|
      builder.rows(rows)
    end
  rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
    []
  end

  def count_collections
    Hyrax::CollectionsService.new(self).search_results.count
  end

  def sort_field
    "system_create_dtsi desc"
  end
end