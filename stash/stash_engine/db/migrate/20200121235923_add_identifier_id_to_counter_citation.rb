class AddIdentifierIdToCounterCitation < ActiveRecord::Migration
  def change
    add_column :stash_engine_counter_citations, :identifier_id, :integer
    add_index :stash_engine_counter_citations, :identifier_id
  end
end
