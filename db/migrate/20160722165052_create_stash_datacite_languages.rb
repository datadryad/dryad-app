class CreateStashDataciteLanguages < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_languages do |t|
      t.string :language
      t.integer :resource_id
      t.timestamps null: false
    end
  end
end
