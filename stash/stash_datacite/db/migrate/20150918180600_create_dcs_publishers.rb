class CreateDcsPublishers < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_publishers do |t|
      t.string :publisher
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
