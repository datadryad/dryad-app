class RemoveIdentifierIdFromStashEngineCounterCitations < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_counter_citations, :identifier_id, :integer
  end
end
