class DropTablesRelatedIdTypesAndRelationTypes < ActiveRecord::Migration
  def change
    drop_table :dcs_related_identifier_types
    drop_table :dcs_relation_types
  end
end
