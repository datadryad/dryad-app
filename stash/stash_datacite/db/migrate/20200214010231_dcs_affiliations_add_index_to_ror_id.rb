class DcsAffiliationsAddIndexToRorId < ActiveRecord::Migration[4.2]
  def change
    add_index(:dcs_affiliations, :ror_id, length: { ror_id: 30 })
  end
end
