class AddIndexToCounterStatsIdentifierId < ActiveRecord::Migration
  def change
    add_index :stash_engine_counter_stats, :identifier_id
  end
end
