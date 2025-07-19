class AddContribGroupRequired < ActiveRecord::Migration[8.0]
  def change
    add_column :dcs_contributor_groupings, :required, :boolean
  end
end
