class CreateIndexJobs < ActiveRecord::Migration
  def change
    create_table :index_jobs do |t|
      t.references :harvest_job, foreign_key: true
      t.text :solr_url
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status, default: 0
    end
  end
end
