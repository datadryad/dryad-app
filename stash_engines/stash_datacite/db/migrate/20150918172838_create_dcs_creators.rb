class CreateDcsCreators < ActiveRecord::Migration
  def change
    create_table :dcs_creators do |t|
      t.string :creator_first_name
      t.string :creator_last_name
      t.integer :name_identifier_id
      t.integer :affliation_id
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
