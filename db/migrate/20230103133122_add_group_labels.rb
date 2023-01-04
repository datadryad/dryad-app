class AddGroupLabels < ActiveRecord::Migration[6.1]
  def up
    add_column :dcs_contributor_groupings, :group_label, :string, after: :name_identifier_id
    execute <<-SQL
      UPDATE dcs_contributor_groupings SET group_label = 'NIH Institute or Center' WHERE contributor_name = 'National Institutes of Health'
    SQL
  end

  def down
    remove_column :dcs_contributor_groupings, :group_label
  end
end
