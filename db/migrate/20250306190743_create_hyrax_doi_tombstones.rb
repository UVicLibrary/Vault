class CreateHyraxDOITombstones < ActiveRecord::Migration[6.1]
  def change
    create_table :hyrax_doi_tombstones do |t|

      t.string :doi
      t.string :hyrax_id
      t.string :reason

      t.timestamps
    end
  end
end
