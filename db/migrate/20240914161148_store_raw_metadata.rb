class StoreRawMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_counter_citations, :metadata, :json, after: :citation
  end
end
