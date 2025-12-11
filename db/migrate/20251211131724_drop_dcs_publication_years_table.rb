class DropDcsPublicationYearsTable < ActiveRecord::Migration[8.0]
  def up
    remove_index :dcs_publication_years, :resource_id
    drop_table :dcs_publication_years
  end

  def down
    create_table :dcs_publication_years do |t|
      t.string :publication_year
      t.integer :resource_id

      t.timestamps null: false
    end
    add_index :dcs_publication_years, :resource_id
  end
end
