class DropTableDcsTitles < ActiveRecord::Migration
  def change
    drop_table :dcs_titles
  end
end
