class DcsAffiliationsAddIndexToRorId < ActiveRecord::Migration
  def change
    add_index(:dcs_affiliations, :ror_id, length: { ror_id: 30 })
  end
end
