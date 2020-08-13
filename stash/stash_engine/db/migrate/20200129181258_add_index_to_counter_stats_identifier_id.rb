class AddIndexToCounterStatsIdentifierId < ActiveRecord::Migration[4.2]
  def change
    add_index :stash_engine_counter_stats, :identifier_id
  end
end
