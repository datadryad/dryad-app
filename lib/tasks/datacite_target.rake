# :nocov:
require_relative 'dash_updater'
namespace :datacite_target do

  # This will update only items that are in non-Dryad tenants
  # Historically, it only included "Dash" items, but now more
  # items have non-Dryad tenants
  desc 'update_dash DOI targets to reflect new environment'
  task update_dash: :environment do
    stash_ids = Tasks::DashUpdater.dash_items_to_update
    stash_ids.each_with_index do |stash_id, idx|
      puts "#{idx + 1}/#{stash_ids.length}: updating #{stash_id.identifier}"
      Tasks::DashUpdater.submit_id_metadata(stash_identifier: stash_id)
      sleep 1
    end
  end

  # this will go through the items in the same order, so if it crashes at a point it can be restarted from that item again
  # saves errors to a separate errors.txt file so we can handle these separately/manually assuming there are only a few
  desc 'update Dryad DOI targets to reflect new environment'
  task update_dryad: :environment do
    $stdout.sync = true

    start_from = 0
    start_from = ARGV[1].to_i unless ARGV[1].blank?

    stash_ids = Tasks::DashUpdater.all_items_to_update

    stash_ids.each_with_index do |stash_id, idx|
      next if idx < start_from

      puts "#{idx + 1}/#{stash_ids.length}: updating #{stash_id.identifier}"

      begin
        Tasks::DashUpdater.submit_id_metadata(stash_identifier: stash_id)
      rescue Stash::Doi::IdGenError, ArgumentError, Net::HTTPClientException => e
        outstr = "\n#{stash_id.id}: #{stash_id.identifier}\n#{e.message}\n"
        File.write('datacite_update_errors.txt', outstr, mode: 'a')
      end
      sleep 1
    end
  end
end
# :nocov:
