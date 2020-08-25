class AddStorageSizeToStashEngineIdentifier < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_identifiers, :storage_size, :bigint, after: :identifier_type
  end
end
