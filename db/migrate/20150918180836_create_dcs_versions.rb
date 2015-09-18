class CreateDcsVersions < ActiveRecord::Migration
  def change
    create_table :dcs_versions do |t|
      t.string :version
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
