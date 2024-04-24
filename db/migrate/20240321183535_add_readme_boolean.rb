class AddReadmeBoolean < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_resources, :display_readme, :boolean, default: true, after: :preserve_curation_status
  end
end
