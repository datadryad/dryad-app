class CreateStashEngineResources < ActiveRecord::Migration
  def change
    create_table :stash_engine_resources do |t|
      t.integer :user_id
      t.integer :current_resource_state_id

      t.timestamps null: false
    end
  end
end
