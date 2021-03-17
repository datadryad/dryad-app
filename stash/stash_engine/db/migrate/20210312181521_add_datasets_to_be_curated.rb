class AddDatasetsToBeCurated < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_curation_stats, :datasets_to_be_curated, :integer
  end
end
