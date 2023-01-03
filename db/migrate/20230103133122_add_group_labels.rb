class AddGroupLabels < ActiveRecord::Migration[6.1]
  def up
    add_column :dcs_contributor_groupings, :group_label, :string, after: :name_identifier_id
  end

  def down
    remove_column :dcs_contributor_groupings, :group_label
  end
end
