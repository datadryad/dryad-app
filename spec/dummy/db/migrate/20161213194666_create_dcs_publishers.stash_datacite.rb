# This migration comes from stash_datacite (originally 20150918180600)
class CreateDcsPublishers < ActiveRecord::Migration
  def change
    create_table :dcs_publishers do |t|
      t.string :publisher
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
