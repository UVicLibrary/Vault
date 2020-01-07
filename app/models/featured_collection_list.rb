class FeaturedCollectionList < ApplicationRecord
  include ActiveModel::Model

  # @param [ActionController::Parameters] a collection of nested perameters
  def featured_collections_attributes=(attributes_collection)
    attributes_collection = attributes_collection.to_h if attributes_collection.respond_to?(:permitted?)
    attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes } if attributes_collection.is_a? Hash

    attributes_collection.each do |attributes|
      if FeaturedCollection.exists?(attributes['id'])
        existing_record = FeaturedCollection.find(attributes['id'])
        existing_record.update(attributes.except('id'))
      else # If a featured collection has been deleted (Record not found)
        attributes_collection.delete(attributes)
        reset_order
      end
    end
  end

  def reset_order
    @featured_collections.each do |collection|
      collection.order = @featured_collections.index(collection) + 1
      collection.save
    end
  end

  def featured_collections
    # return @featured_collections if @featured_collections
    @featured_collections ||= FeaturedCollection.all
    #add_solr_document_to_collections
  end

  def add_solr_document_to_collections
    collection_presenters.each do |presenter|
      collection_with_id(presenter.id).presenter = presenter
    end
  end

  def ids
    featured_collections.pluck(:collection_id)
  end

  def collection_presenters
    Hyrax::PresenterFactory.build_for(ids: ids,
                                      presenter_class: Hyrax::CollectionPresenter,
                                      presenter_args: nil)
  end

  def collection_with_id(id)
    @featured_collections.find { |c| c.collection_id == id }
  end

  def presenter_with_id(id)
    collection_presenters.find(id).first
  end

end
