# This migration comes from stash_engine (originally 20160715183015)
class DropDelayedJobs < ActiveRecord::Migration
  def change
    drop_table :delayed_jobs
  end
end
