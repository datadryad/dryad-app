class IncreaseDescriptionToMediumtext < ActiveRecord::Migration[4.2]
  def change
    change_column :dcs_descriptions, :description, :text, limit: 16.megabytes - 1
  end
end
