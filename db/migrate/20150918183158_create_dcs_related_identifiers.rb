class CreateDcsRelatedIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_related_identifiers do |t|
      t.string :related_identifier
      t.integer :related_identifier_type_id
      t.integer :relation_type_id
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
