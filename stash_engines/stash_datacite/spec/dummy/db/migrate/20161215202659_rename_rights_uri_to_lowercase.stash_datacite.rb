# This migration comes from stash_datacite (originally 20160527210518)
class RenameRightsUriToLowercase < ActiveRecord::Migration
  def change
    rename_column(:dcs_rights, :rights_URI, :rights_uri)
  end
end
