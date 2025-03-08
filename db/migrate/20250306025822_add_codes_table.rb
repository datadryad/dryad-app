class AddCodesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :stash_engine_edit_codes do |t|
      t.bigint :author_id
      t.string :edit_code
      t.integer :role
      t.boolean :applied, default: false
      t.timestamps
    end
    add_index :stash_engine_edit_codes, :author_id
    add_index :stash_engine_edit_codes, :edit_code
  end
end
