class AddHiddenToStashDataciteRelatedIdentifier < ActiveRecord::Migration[5.2]
  def change
    add_column :dcs_related_identifiers, :hidden, :boolean, default: false
  end
end
