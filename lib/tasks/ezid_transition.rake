
namespace :ezid_transition do

  # this will find ezid datasets over 1 year old that are not submitted and remove them, set RAILS_ENV=production
  # for real removals from production
  task remove_old_unsubmitted: :environment do

    stash_ids = StashEngine::Identifier.where('created_at < ?', 1.year.ago).
      where("identifier NOT LIKE '10.5061%'")

    puts "Found #{stash_ids.count} identifiers over 1 year old from EZID shoulders"

    count = 0
    stash_ids.each do |stash_id|
      next if stash_id.resources.count > 1 || stash_id.resources.first&.current_state == 'submitted'

      count += 1
      # verified that there is a model callback to remove S3 uploaded staging files before destroying
      puts "Destroying identifier: #{stash_id.identifier}"
      stash_id.destroy!
    end

    puts "Removed #{count} identifiers over 1 year old from EZID shoulders"
  end
end