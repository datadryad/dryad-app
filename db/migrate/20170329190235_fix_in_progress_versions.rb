class FixInProgressVersions < ActiveRecord::Migration
  def change
    StashEngine::Identifier.find_each do |identifier|
      lsv = identifier.last_submitted_version
      next unless lsv
      lsv_stash_version = lsv.version_number
      lsv_merritt_version = lsv.merritt_version

      identifier.resources.in_progress.find_each do |resource|
        in_progress_version = resource.stash_version
        in_progress_version.version = lsv_stash_version + 1
        in_progress_version.merritt_version = lsv_merritt_version + 1
        in_progress_version.save!
      end
    end
  end
end

