class LogoTable < ActiveRecord::Migration[7.0]
  def change
    create_table :stash_engine_logos do |t|
      t.longtext :data
      t.timestamps
    end
    rename_column :stash_engine_tenants, :logo, :logo_id
  end
end