class AddTypeToStashEngineProposedChanges < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_proposed_changes, :xref_type, :string
  end
end
