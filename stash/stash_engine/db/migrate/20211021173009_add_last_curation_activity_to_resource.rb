class AddLastCurationActivityToResource < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_resources, :last_curation_activity_id, :integer
  end
end
