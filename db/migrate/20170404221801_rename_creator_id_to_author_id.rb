class RenameCreatorIdToAuthorId < ActiveRecord::Migration
  def change
    # authors preserve creators' ID values
    rename_column :dcs_affiliations, :creator_id, :author_id
  end
end
