class CreateFeaturedCollectionLists < ActiveRecord::Migration[5.1]
  def change
    create_table :featured_collection_lists do |t|

      t.timestamps
    end
  end
end
