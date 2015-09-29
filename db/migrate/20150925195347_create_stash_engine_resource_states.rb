class CreateStashEngineResourceStates < ActiveRecord::Migration
  def change
    create_table :stash_engine_resource_states do |t|
      t.integer :user_id
      t.column :resource_state, :integer, default: 0

      t.timestamps null: false
    end
  end
end
