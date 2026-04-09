class AddDescriptionTypeIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :dcs_descriptions, :description_type
  end
end
