class DropTablesRelatedIdTypesAndRelationTypes < ActiveRecord::Migration[4.2]
  def change
    drop_table :dcs_related_identifier_types
    drop_table :dcs_relation_types
  end
end
