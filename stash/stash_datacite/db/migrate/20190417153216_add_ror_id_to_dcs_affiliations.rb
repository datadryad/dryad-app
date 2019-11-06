class AddRorIdToDcsAffiliations < ActiveRecord::Migration
  def change
    add_column :dcs_affiliations, :ror_id, :string
  end
end
