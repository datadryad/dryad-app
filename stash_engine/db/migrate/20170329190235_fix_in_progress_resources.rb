class FixInProgressResources < ActiveRecord::Migration
  def change
    StashEngine::Identifier.find_each do |identifier|
      last_submitted = identifier.last_submitted_resource
      next unless last_submitted
      lsv_stash_version = last_submitted.version_number
      lsv_merritt_version = last_submitted.merritt_version

      identifier.resources.in_progress.find_each do |resource|
        in_progress_resource = resource.stash_version
        in_progress_resource.version = lsv_stash_version + 1
        in_progress_resource.merritt_version = lsv_merritt_version + 1
        in_progress_resource.save!
      end
    end
  end
end
