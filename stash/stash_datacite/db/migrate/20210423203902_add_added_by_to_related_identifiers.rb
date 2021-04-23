class AddAddedByToRelatedIdentifiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dcs_related_identifiers, :status, :integer, default: 0 # default
  end
end
