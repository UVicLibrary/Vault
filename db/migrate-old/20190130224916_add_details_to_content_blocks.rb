class AddDetailsToContentBlocks < ActiveRecord::Migration[5.1]
  def change
    add_column :content_blocks, :researcher_name, :string
    add_column :content_blocks, :researcher_title, :string
  end
end
