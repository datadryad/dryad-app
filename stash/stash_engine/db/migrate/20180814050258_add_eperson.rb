class AddEperson < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_users, :eperson_id, :integer
  end
end
