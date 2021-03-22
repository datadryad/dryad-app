class AddDateIndexToCurationStats < ActiveRecord::Migration[5.2]
  def change
      add_index :stash_engine_curation_stats, :date, unique: true
  end
end
