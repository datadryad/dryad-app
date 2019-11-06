class AddEperson < ActiveRecord::Migration
  def change
    add_column :stash_engine_users, :eperson_id, :integer
  end
end
