class AddTenantLogos < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_tenants, :logo, :longtext, after: :sponsor_id
  end
end
