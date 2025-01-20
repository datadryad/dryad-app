class AddStats < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_curation_stats, :datasets_unclaimed, :integer, after: :datasets_to_be_curated
    add_column :stash_engine_curation_stats, :new_datasets, :integer, after: :date
  end
end
