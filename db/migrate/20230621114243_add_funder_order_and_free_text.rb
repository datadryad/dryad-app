class AddFunderOrderAndFreeText < ActiveRecord::Migration[6.1]
  def change
    add_column :dcs_contributors, :funder_order, :integer, default: nil
    add_column :dcs_contributors, :award_description, :string, default: nil
  end
end
