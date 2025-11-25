class SetContributorRorDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :dcs_contributors, :identifier_type, from: nil, to: 'ror'
  end
end
