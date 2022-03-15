class AddAffiliationIdToStashEngineUsers < ActiveRecord::Migration[4.2]
  def change
    add_reference :stash_engine_users, :affiliation, index: true
  end
end
