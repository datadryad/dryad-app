class AddCorresp < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_authors, :corresp, :boolean, default: false
  end
end
