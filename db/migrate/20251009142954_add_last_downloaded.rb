class AddLastDownloaded < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_identifiers, :downloaded_at, :datetime, after: :updated_at
  end
end

