class AddCedarToResource < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_resources, :cedar_json, :text
  end
end
