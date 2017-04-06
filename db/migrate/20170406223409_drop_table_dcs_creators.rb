class DropTableDcsCreators < ActiveRecord::Migration
  def change
    drop_table :dcs_creators
  end
end
