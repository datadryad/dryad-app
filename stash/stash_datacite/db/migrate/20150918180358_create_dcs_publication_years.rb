class CreateDcsPublicationYears < ActiveRecord::Migration
  def change
    create_table :dcs_publication_years do |t|
      t.string :publication_year
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
