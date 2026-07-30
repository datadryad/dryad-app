class IndexRorIds < ActiveRecord::Migration[8.0]
  def change
    add_index :stash_engine_ror_orgs, :ror_id
  end
end
