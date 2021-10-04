class IndexOrcidOnStashEngineUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :stash_engine_users, :orcid, length: { orcid: 19 }
  end
end
