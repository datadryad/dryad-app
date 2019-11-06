class AddAffiliationIdToStashEngineUsers < ActiveRecord::Migration
  def change
    add_reference :stash_engine_users, :affiliation, index: true
  end
end
