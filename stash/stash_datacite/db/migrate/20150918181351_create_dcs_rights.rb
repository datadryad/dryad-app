class CreateDcsRights < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_rights do |t|
      t.string :rights
      t.text   :rights_URI
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
