class DropTableDcsTitles < ActiveRecord::Migration[4.2]
  def change
    drop_table :dcs_titles
  end
end
