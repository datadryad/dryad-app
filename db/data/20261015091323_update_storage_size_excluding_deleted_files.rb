# frozen_string_literal: true

class UpdateStorageSizeExcludingDeletedFiles < ActiveRecord::Migration[8.0]
  def up
    # update storage size for all identifiers that have delete data files
    StashEngine::Identifier.where(id: StashEngine::DataFile.where.not(file_deleted_at: nil).joins(:resource).select(:identifier_id).distinct).each do |id|
      next if id.resources.count == 1

      total_dataset_size = id.resources.sum { |r| r.data_files.included_in_total_storage.sum(&:upload_file_size) }
      pp "Updating storage size for #{id.id} from #{id.storage_size} -> #{total_dataset_size}" if id.storage_size != total_dataset_size
      id.update(storage_size: total_dataset_size)
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
