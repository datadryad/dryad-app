class CreateGlobalStates < ActiveRecord::Migration[6.1]
  def change
    create_table :stash_engine_global_states do |t|
      t.string :key
      t.json :state

      t.timestamps
    end
  end
end
