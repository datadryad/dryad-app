class CreateDcsContributors < ActiveRecord::Migration
  def change
    create_table :dcs_contributors do |t|
      t.string :contributor_name
      t.column :contributor_type, :integer, default: 0
      t.integer :name_identifier_id
      t.integer :affliation_id
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
