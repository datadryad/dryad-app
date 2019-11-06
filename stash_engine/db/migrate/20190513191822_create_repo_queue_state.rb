class CreateRepoQueueState < ActiveRecord::Migration
  def change
    create_table :stash_engine_repo_queue_states do |t|
      t.references :resource, index: true
          t.column :state, "ENUM('rejected_shutting_down', 'enqueued', 'processing', 'completed', 'errored') DEFAULT NULL"
      t.string :hostname, length: 100
      t.timestamps null: false
    end
  end
end
