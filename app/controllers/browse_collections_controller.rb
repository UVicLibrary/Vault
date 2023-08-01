class BrowseCollectionsController < Hyrax::HomepageController

  class_attribute :search_builder_class
  self.search_builder_class = BrowseCollectionsSearchBuilder

  def autocomplete
    json = collections.each_with_object([]) do |coll, arr|
      arr.push({ title: coll.title_or_label, link: hyrax.collection_path(coll.id), id: coll.id })
    end.to_json
    render json: json
  end

  private

  # Return all collections
  # def collections(options = {})
  #   builder = self.search_builder_class.new(self)
  #   # Override default search to be title A-Z instead of relevance
  #   sort = options[:sort] ||= builder.default_sort_field
  #   rows = options[:rows] ||= count_collections
  #   builder.merge(sort: sort, start: options[:start], rows: rows)
  #   response = repository.search(builder)
  #   response.documents
  # rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
  #   []
  # end

  def spotlight_exhibits
    response = Faraday.get 'https://exhibits.library.uvic.ca/exhibits/json'
    omitted = ['Exhibition Tutorials',
               'Experiential Learning at the University of Victoria Faculty of Law']
    array = []
    filtered_response = JSON.parse(response.body).reject { |key, _| omitted.include? key }
    filtered_response.each { |_, value| array.push({ 'exhibit' => value }) }
    array
  end

end
