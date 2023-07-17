class AddSubjectsToProposedChanges < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_proposed_changes, :subjects, :text, default: nil
  end
end
