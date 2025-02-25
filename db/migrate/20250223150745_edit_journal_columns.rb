class EditJournalColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_journals, :allow_blackout, :boolean
    remove_column :stash_engine_journals, :allow_embargo, :boolean
    change_column_default :stash_engine_journals, :allow_review_workflow, from: nil, to: true
    add_column :stash_engine_journals, :preprint_server, :boolean, default: false
  end
end
