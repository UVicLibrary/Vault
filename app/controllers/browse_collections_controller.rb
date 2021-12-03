class BrowseCollectionsController < Hyrax::HomepageController

  class_attribute :search_builder_class
  self.search_builder_class = BrowseCollectionsSearchBuilder

  def index
    builder = self.search_builder_class.new(self).rows(8)
    response = repository.search(builder).response
    @total_count = response['numFound']
    @collection_presenters = build_presenters(response['docs'])
  end

  def load_more
    respond_to do |format|
      results = collections({ start: params[:start].to_i, rows: 8, sort: params[:sort] })
      presenters = build_presenters(results)
      format.js { render 'load_more.js.erb', locals: { presenters: presenters } }
    end
  end

  private

  def build_presenters(documents)
    Hyrax::PresenterFactory.build_for(ids: documents.pluck(:id),
                                      presenter_class: Hyrax::CollectionPresenter,
                                      presenter_args: nil)
  end

  # Return all collections
  def collections(options = {})
    builder = self.search_builder_class.new(self).rows(options[:rows])
    # Override default search to be title A-Z instead of relevance
    sort = options[:sort] ||= builder.default_sort_field
    builder.merge(sort: sort, start: options[:start])
    response = repository.search(builder)
    response.documents
  rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
    []
  end
      
  def spotlight_exhibits
    response = Faraday.get 'https://exhibits.library.uvic.ca/exhibits/json'
    to_omit = ['Exhibition Tutorials',
               'Experiential Learning at the University of Victoria Faculty of Law']
    array = []
    filtered_response = JSON.parse(response.body).reject { |key, _| to_omit.include? key }
    filtered_response.each { |_, value| array.push({ 'exhibit' => value }) }
    array
  end

end