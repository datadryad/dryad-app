class AddFixedIdToRelatedIdentifiers < ActiveRecord::Migration[5.0]
  def change
    add_column :dcs_related_identifiers, :fixed_id, :text
  end
end
