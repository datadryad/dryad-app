class IncreaseDescriptionToMediumtext < ActiveRecord::Migration
  def change
    change_column :dcs_descriptions, :description, :text, limit: 16.megabytes - 1
  end
end
