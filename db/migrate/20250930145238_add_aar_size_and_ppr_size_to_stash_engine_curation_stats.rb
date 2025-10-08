class AddAarSizeAndPprSizeToStashEngineCurationStats < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_curation_stats, :aar_size, :integer
    add_column :stash_engine_curation_stats, :ppr_size, :integer
  end
end
