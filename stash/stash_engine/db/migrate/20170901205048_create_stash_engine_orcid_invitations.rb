class CreateStashEngineOrcidInvitations < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_orcid_invitations do |t|
      t.string :email
      t.integer :identifier_id
      t.string :first_name
      t.string :last_name
      t.string :secret
      t.string :orcid
    end
  end
end
