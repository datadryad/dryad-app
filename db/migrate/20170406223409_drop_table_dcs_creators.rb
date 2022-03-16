class DropTableDcsCreators < ActiveRecord::Migration[4.2]
  def change
    drop_table :dcs_creators
  end
end
