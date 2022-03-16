class CreateDcsVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_versions do |t|
      t.string :version
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
