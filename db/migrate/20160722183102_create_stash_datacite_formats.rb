class CreateStashDataciteFormats < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_formats do |t|
      t.text :format
      t.integer :resource_id, null: false

      t.timestamps null: false
    end
  end
end
