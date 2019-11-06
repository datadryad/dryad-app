class AddIndicesToStashEngineOrcidInvitation < ActiveRecord::Migration
  def change
    add_index :stash_engine_orcid_invitations, :email
    add_index :stash_engine_orcid_invitations, :identifier_id
    add_index :stash_engine_orcid_invitations, :secret
    add_index :stash_engine_orcid_invitations, :orcid
  end
end
