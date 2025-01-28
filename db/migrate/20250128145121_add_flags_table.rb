class AddFlagsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :stash_engine_flags do |t|
      t.integer :flag
      t.string :flaggable_type
      t.string :flaggable_id
      t.text :note
      t.timestamps
    end
    add_index :stash_engine_flags, [:flaggable_type, :flaggable_id]
  end
end
