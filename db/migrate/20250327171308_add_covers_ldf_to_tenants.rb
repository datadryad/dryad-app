class AddCoversLdfToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_tenants, :covers_ldf, :boolean, default: false, after: :covers_dpc
    add_column :stash_engine_tenants, :low_income_country, :boolean, default: false, after: :covers_ldf
  end
end
