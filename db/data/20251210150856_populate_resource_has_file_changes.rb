# frozen_string_literal: true

class PopulateResourceHasFileChanges < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Resource.where(id: StashEngine::GenericFile.where(file_state: %w[created deleted], type: 'StashEngine::DataFile').select(:resource_id)).update_all(has_file_changes: true)
  end

  def down
    StashEngine::Resource.update_all(has_file_changes: false)
  end
end
