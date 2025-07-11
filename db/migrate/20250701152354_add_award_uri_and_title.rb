class AddAwardUriAndTitle < ActiveRecord::Migration[8.0]
  def change
    add_column :dcs_contributors, :award_uri, :string, after: :award_number
    add_column :dcs_contributors, :award_title, :string, after: :award_description
  end
end
