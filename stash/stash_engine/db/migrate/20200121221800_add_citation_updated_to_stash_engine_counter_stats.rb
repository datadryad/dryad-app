class AddCitationUpdatedToStashEngineCounterStats < ActiveRecord::Migration
  def change
    # give an old default so it will out of date and be rechecked
    add_column :stash_engine_counter_stats, :citation_updated, :datetime, default: '2018-01-01'
  end
end
