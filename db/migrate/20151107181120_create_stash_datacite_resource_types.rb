class CreateStashDataciteResourceTypes < ActiveRecord::Migration
  def change
    create_table :stash_datacite_resource_types do |t|

      t.timestamps null: false
    end
  end
end
