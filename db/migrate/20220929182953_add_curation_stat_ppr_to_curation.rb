class AddCurationStatPprToCuration < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_curation_stats, :ppr_to_curation, :integer
  end
end
