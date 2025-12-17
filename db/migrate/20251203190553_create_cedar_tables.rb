class CreateCedarTables < ActiveRecord::Migration[8.0]
  def change
    rename_column :stash_engine_resources, :cedar_json, :old_cedar_json
    create_table :cedar_word_banks do |t|
      t.string :label
      t.text :keywords
      t.timestamps
    end
    create_table :cedar_templates, id: :string do |t|
      t.string :title
      t.json :template
      t.bigint :word_bank_id
      t.timestamps
    end
    add_index :cedar_templates, :id
    add_index :cedar_templates, :word_bank_id
    add_foreign_key :cedar_templates, :cedar_word_banks, column: :word_bank_id
    create_table :cedar_json do |t|
      t.integer :resource_id
      t.string :template_id
      t.json :json
      t.timestamps
    end
    add_index :cedar_json, :resource_id
    add_index :cedar_json, :template_id
    add_foreign_key :cedar_json, :cedar_templates, column: :template_id
    add_foreign_key :cedar_json, :stash_engine_resources, column: :resource_id
  end
end
