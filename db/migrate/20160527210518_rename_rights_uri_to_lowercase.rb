class RenameRightsUriToLowercase < ActiveRecord::Migration[4.2]
  def change
    rename_column(:dcs_rights, :rights_URI, :rights_uri)
  end
end
