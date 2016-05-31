class RenameRightsUriToLowercase < ActiveRecord::Migration
  def change
    rename_column(:dcs_rights, :rights_URI, :rights_uri)
  end
end
