class CreateResourceUsages < ActiveRecord::Migration
  def change
    create_table :stash_engine_resource_usages do |t|
      t.integer :resource_id
      t.integer :downloads
      t.integer :views
    end
  end
end
