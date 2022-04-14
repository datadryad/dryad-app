class AddIdentifierIdToCounterCitation < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_counter_citations, :identifier_id, :integer
    add_index :stash_engine_counter_citations, :identifier_id
  end
end
