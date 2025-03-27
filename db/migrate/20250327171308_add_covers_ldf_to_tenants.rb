class AddCoversLdfToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_tenants, :covers_ldf, :string, after: :covers_dpc
  end
end
