class RemovePprEndDate < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_resources, :peer_review_end_date, :datetime
  end
end
