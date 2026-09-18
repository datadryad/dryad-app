# frozen_string_literal: true

class UpdateStorageSize < ActiveRecord::Migration[8.0]
  def up
    # some of these will be legitimately the same, but this also won't hurt anything
    StashEngine::Identifier.joins(:latest_resource).where('storage_size = total_file_size') each do |id|
      next if id.resources.count == 1

      total_dataset_size = id.resources.sum { |r| r.data_files.created.sum(&:upload_file_size) }
      id.update(storage_size: total_dataset_size)
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
