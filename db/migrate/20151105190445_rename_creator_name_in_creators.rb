class RenameCreatorNameInCreators < ActiveRecord::Migration
  def change
    rename_column :dcs_creators, :creator_name, :creator_first_name
  end
end
