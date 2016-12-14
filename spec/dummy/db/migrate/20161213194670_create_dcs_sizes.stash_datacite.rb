# This migration comes from stash_datacite (originally 20150918182644)
class CreateDcsSizes < ActiveRecord::Migration
  def change
    create_table :dcs_sizes do |t|
      t.string :size
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
