# TODO: get this out of StashEngine into Stash::Merritt
class AddMerrittVersionToStashEngineVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_versions, :merritt_version, :integer
    StashEngine::Version.update_all('merritt_version = version')
  end
end
