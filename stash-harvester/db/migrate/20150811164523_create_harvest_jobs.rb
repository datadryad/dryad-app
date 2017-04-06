class CreateHarvestJobs < ActiveRecord::Migration
  def change
    create_table :harvest_jobs do |t|
      t.datetime :from_time
      t.datetime :until_time
      t.text :query_url
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status, default: 0
    end
  end
end
