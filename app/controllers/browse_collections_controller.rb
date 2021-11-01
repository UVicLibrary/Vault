class BrowseCollectionsController < Hyrax::HomepageController
  require 'faraday'

  def index
    # see hyrax/homepage_controller#index
    super
    # Make hashes from Vault collection results
    featured_collections = @featured_collection_list.collection_presenters.map do |presenter|
       document = presenter.solr_document
       if document.thumbnail_path
         if document.thumbnail_path.include? "uploaded_collection_thumbnails"
           # use the higher resolution derivative
           new_path = document.thumbnail_path.gsub('_thumbnail.jpg','_card.jpg')
         else
           # If string contains thumbnail dimensions, change them
           new_path = document.thumbnail_path.gsub '!150,300', '!500,900'
         end
       else # use placeholder
         new_path = asset_path 'collection.png', skip_pipeline: true
       end
       { 'collection' => {
           'title' => presenter.title.first,
           'description' => presenter.description.first,
           'url' => presenter.show_path.gsub('/dashboard',''),
           'thumbnail' => new_path }
       }
    end
    @total_results = (featured_collections + spotlight_exhibits).sort_by { |hash| hash[hash.keys.first]['title'] }
  end

  private
      
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