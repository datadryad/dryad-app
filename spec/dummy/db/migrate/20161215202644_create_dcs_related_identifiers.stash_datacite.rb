# This migration comes from stash_datacite (originally 20150918183158)
class CreateDcsRelatedIdentifiers < ActiveRecord::Migration
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
