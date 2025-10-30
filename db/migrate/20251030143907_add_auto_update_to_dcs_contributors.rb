class AddAutoUpdateToDcsContributors < ActiveRecord::Migration[8.0]
  def change
    add_column :dcs_contributors, :auto_update, :boolean, default: true
  end
end
