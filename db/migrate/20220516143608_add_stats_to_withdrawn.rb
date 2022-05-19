class AddStatsToWithdrawn < ActiveRecord::Migration[5.2]
  def change
     add_column :stash_engine_curation_stats, :datasets_to_withdrawn, :integer, after: :datasets_to_embargoed
  end
end
