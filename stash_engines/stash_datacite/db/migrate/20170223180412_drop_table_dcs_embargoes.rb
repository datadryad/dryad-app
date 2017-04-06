class DropTableDcsEmbargoes < ActiveRecord::Migration
  def change
    drop_table :dcs_embargoes
  end
end
