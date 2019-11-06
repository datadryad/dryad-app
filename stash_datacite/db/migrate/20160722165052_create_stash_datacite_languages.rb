class CreateStashDataciteLanguages < ActiveRecord::Migration
  def change
    create_table :dcs_languages do |t|
      t.string :language
      t.integer :resource_id
      t.timestamps null: false
    end
  end
end
