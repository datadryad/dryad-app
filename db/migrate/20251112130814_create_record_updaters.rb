class CreateRecordUpdaters < ActiveRecord::Migration[8.0]
  def up
    create_table :record_updaters do |t|
      t.integer :record_id
      t.string :record_type
      t.integer :status, default: 0
      t.json :update_data
      t.integer :user_id
      t.string :data_type

      t.timestamps
    end

    add_index :record_updaters, [:record_type, :record_id]
    add_index :record_updaters, :status
    add_index :record_updaters, :data_type
  end

  def down
    remove_index :record_updaters, :data_type
    remove_index :record_updaters, :status
    remove_index :record_updaters, [:record_type, :record_id]
    drop_table :record_updaters
  end
end
