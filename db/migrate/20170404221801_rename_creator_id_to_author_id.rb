class RenameCreatorIdToAuthorId < ActiveRecord::Migration[4.2]
  def change
    # authors preserve old creators' ID values
    rename_column :dcs_affiliations_creators, :creator_id, :author_id
    rename_table :dcs_affiliations_creators, :dcs_affiliations_authors
  end
end
