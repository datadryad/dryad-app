class AddProvisionalCompleteToRepoQueueState < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
      ALTER TABLE stash_engine_repo_queue_states MODIFY `state` ENUM('rejected_shutting_down', 'enqueued', 'processing', 'completed',
        'errored', 'provisional_complete') DEFAULT NULL
    SQL
  end
end
