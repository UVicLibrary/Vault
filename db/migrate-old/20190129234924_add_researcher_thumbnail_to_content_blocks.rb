class AddResearcherThumbnailToContentBlocks < ActiveRecord::Migration[5.1]
  def change
    add_column :content_blocks, :researcher_thumbnail, :string
  end
end
