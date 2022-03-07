class CreateStashDataciteAlternateIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_alternate_identifiers do |t|
      t.text :alternate_identifier
      t.text :alternate_identifier_type
      t.integer :resource_id, null: false

      t.timestamps null: false
    end
  end
end
