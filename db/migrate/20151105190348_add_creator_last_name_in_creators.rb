class AddCreatorLastNameInCreators < ActiveRecord::Migration
  def change
    add_column :dcs_creators, :creator_last_name, :string
  end
end
