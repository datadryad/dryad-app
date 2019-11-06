class RemoveResourceIdFromDcsSubjects < ActiveRecord::Migration
  def up
    remove_column :dcs_subjects, :resource_id
  end

  def down
    add_column :dcs_subjects, :resource_id, :integer
  end
end
