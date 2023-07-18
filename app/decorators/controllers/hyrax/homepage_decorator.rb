require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/homepage_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0

Hyrax::HomepageController.class_eval do
  # For 'Browse by Time Period' facet
  include BlacklightRangeLimit::ControllerOverride

  def index
    @presenter = presenter_class.new(current_ability, collections)
    @featured_researcher = ContentBlock.for(:researcher)
    @marketing_text = ContentBlock.for(:marketing)
    @featured_work_list = FeaturedWorkList.new
    @announcement_text = ContentBlock.for(:announcement)


    if request.base_url.include? "vault"
      @featured_collection_list = FeaturedCollectionList.new

      # Homepage facet links are configured via VaultHomepageHelper

      # Used by the homepage "Time period" facet
      @response = search_results(q: '', sort: sort_field, rows: 48)[0]

      # Used by the "List All" list of collections
      @collection_list_presenters = build_presenters(collections.sort_by(&:title), Hyrax::CollectionPresenter)

      # Used by the All Collections, Recent Collections tabs tabs
      @collection_card_presenters = @collection_list_presenters.slice(0,8)
      @recent_collection_presenters = recent_collection_presenters.slice(0,8)
      # Used by the Recent Works tab
      @work_count = works_by_date_desc.count
      @recent_work_presenters = recent_work_presenters.slice(0,8)
    else
      recent
    end
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
    build_presenters(works_by_date_desc, VaultWorkShowPresenter)
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
    # q: '{!field f=has_model_ssim}GenericWork' doesn't seem to work despite
    # what the documentation says
    (_, results) = search_results(q: '', sort: sort_field, rows: 48)
    results.select{|w| w["has_model_ssim"] == ["GenericWork"]}
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
    Collection.all.count
  end

  def sort_field
    "system_create_dtsi desc"
  end
end