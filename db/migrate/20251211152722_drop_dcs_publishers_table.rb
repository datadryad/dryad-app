class DropDcsPublishersTable < ActiveRecord::Migration[8.0]
  def up
    remove_index :dcs_publishers, :resource_id
    drop_table :dcs_publishers
  end

  def down
    create_table :dcs_publishers do |t|
      t.string :publisher
      t.integer :resource_id

      t.timestamps null: false
    end
    add_index :dcs_publishers, :resource_id
  end
end
