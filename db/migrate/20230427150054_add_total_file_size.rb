class AddTotalFileSize < ActiveRecord::Migration[6.1]
  def up
    add_column :stash_engine_resources, :total_file_size, :bigint, after: :old_resource_id
    StashEngine::Resource.all.each do |r|
      # get existing file sizes
      r.update_column(:total_file_size, StashEngine::DataFile.where(resource_id: r.id).sum(:upload_file_size))
    end
  end

  def down
    remove_column :stash_engine_resources, :total_file_size
  end
end
