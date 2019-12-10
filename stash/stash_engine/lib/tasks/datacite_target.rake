require_relative 'datacite_target/dash_updater'
namespace :datacite_target do

  desc 'update_dash DOI targets to reflect new environment'
  task update_dash: :environment do
    stash_ids = DashUpdater.dash_items_to_update
    stash_ids.each_with_index do |stash_id, idx|
      puts "#{idx + 1}/#{stash_ids.length}: updating #{stash_id.identifier}"
      DashUpdater.submit_id_metadata(stash_identifier: stash_id)
      sleep 1
    end
  end

end
