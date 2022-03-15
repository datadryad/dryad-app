class DropTableDcsEmbargoes < ActiveRecord::Migration[4.2]
  def change
    drop_table :dcs_embargoes
  end
end
