class AddCreatorMiInCreators < ActiveRecord::Migration
  def change
    add_column :dcs_creators, :creator_middle_name, :string
  end
end
