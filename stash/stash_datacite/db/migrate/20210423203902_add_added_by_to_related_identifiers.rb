class AddAddedByToRelatedIdentifiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dcs_related_identifiers, :added_by, :integer, default: 0 # default
  end
end
