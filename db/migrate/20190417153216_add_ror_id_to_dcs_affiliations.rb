class AddRorIdToDcsAffiliations < ActiveRecord::Migration[4.2]
  def change
    add_column :dcs_affiliations, :ror_id, :string
  end
end
