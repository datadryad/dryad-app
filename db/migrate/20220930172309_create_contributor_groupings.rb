class CreateContributorGroupings < ActiveRecord::Migration[5.2]
  def change
    create_table :dcs_contributor_groupings do |t|
      t.text :contributor_name
      t.integer :contributor_type, default: 6
      t.integer :identifier_type, default: 2
      t.string :name_identifier_id
      t.json :json_contains

      t.timestamps
    end
  end
end
