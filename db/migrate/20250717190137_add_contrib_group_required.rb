class AddContribGroupRequired < ActiveRecord::Migration[8.0]
  def change
    remove_column :dcs_contributor_groupings, :contributor_type, "ENUM('funder') DEFAULT 'funder'"
    add_column :dcs_contributor_groupings, :required, :boolean
  end
end
