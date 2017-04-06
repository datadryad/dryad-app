class CreateIndexJobs < ActiveRecord::Migration
  def change
    create_table :index_jobs do |t|
      t.references :harvest_job, foreign_key: true
      t.text :solr_url
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status, default: 0
    end

    # TODO: Remove these once foreign_key works
    add_index :index_jobs, :harvest_job_id
  end
end
