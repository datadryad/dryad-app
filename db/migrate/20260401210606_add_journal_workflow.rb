class AddJournalWorkflow < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_journals, :data_workflow, :json
    create_table :data_review_logs do |t|
      t.integer :resource_id
      t.integer :user_id
      t.integer :journal_id
      t.string :status
      t.string :note      
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :data_review_logs, [:resource_id, :id]
    add_index :data_review_logs, :deleted_at
  end
end
