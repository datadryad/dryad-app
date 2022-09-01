class ChangeErrorTextSizeForZenodoCopies < ActiveRecord::Migration[5.2]
  def self.up
    change_column :stash_engine_zenodo_copies, :error_info, :text, limit: 16.megabytes - 1
  end

  def self.down
    change_column :stash_engine_zenodo_copies, :error_info, :text, limit: 64.kilobytes - 1
  end
end
