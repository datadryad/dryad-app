class AddInvitedAtToStashEngineOrcidInvitations < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_orcid_invitations, :invited_at, :datetime, null: false
    add_column :stash_engine_orcid_invitations, :accepted_at, :datetime, null: true
  end
end
