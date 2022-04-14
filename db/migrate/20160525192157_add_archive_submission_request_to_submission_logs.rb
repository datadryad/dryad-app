class AddArchiveSubmissionRequestToSubmissionLogs < ActiveRecord::Migration[4.2]
  def up
    add_column :stash_engine_submission_logs, :archive_submission_request, :text
  end

  def down
    remove_column :stash_engine_submission_logs, :archive_submission_request
  end
end
