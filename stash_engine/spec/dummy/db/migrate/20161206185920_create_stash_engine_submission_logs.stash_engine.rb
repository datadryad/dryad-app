# This migration comes from stash_engine (originally 20150929170816)
class CreateStashEngineSubmissionLogs < ActiveRecord::Migration
  def change
    create_table :stash_engine_submission_logs do |t|
      t.integer :resource_id
      t.text :archive_response

      t.timestamps null: false
    end
  end
end
