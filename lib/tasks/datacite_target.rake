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

  # example: rails datacite_target:update_by_publication -- --start 2024-06-25 --end 2024-06-26
  desc 'update Dryad DOI targets for a specific date range of publication'
  task update_by_publication: :environment do
    $stdout.sync = true
    options = Tasks::ArgsParser.parse(%i[start end])

    if !options[:start] || !options[:end]
      puts 'Takes 2 dates in format YYYY-MM-DD to create a range for DOI updates'
      exit
    end

    stash_ids = Tasks::DashUpdater.dated_items_to_update(options[:start].to_s, options[:end].to_s)
    stash_ids.each_with_index do |stash_id, idx|
      puts "#{idx + 1}/#{stash_ids.length}: updating #{stash_id.identifier}"
      begin
        Tasks::DashUpdater.submit_id_metadata(stash_identifier: stash_id)
      rescue Datacite::DoiGenError, ArgumentError, Net::HTTPClientException => e
        outstr = "\n#{stash_id.id}: #{stash_id.identifier}\n#{e.message}\n"
        File.write('datacite_update_errors.txt', outstr, mode: 'a')
      end
      sleep 1
    end
    exit
  end

  # this will go through the items in the same order, so if it crashes at a point it can be restarted from that item again
  # saves errors to a separate errors.txt file so we can handle these separately/manually assuming there are only a few
  # example: rails datacite_target:update_dryad -- --start 10
  desc 'update Dryad DOI targets to reflect new environment'
  task update_dryad: :environment do
    $stdout.sync = true
    options = Tasks::ArgsParser.parse([:start])

    start_from = 0
    start_from = options[:start].to_i if options[:start]

    stash_ids = Tasks::DashUpdater.all_items_to_update

    stash_ids.each_with_index do |stash_id, idx|
      next if idx < start_from

      puts "#{idx + 1}/#{stash_ids.length}: updating #{stash_id.identifier}"

      begin
        Tasks::DashUpdater.submit_id_metadata(stash_identifier: stash_id)
      rescue Datacite::DoiGenError, ArgumentError, Net::HTTPClientException => e
        outstr = "\n#{stash_id.id}: #{stash_id.identifier}\n#{e.message}\n"
        File.write('datacite_update_errors.txt', outstr, mode: 'a')
      end
      sleep 1
    end
    exit
  end
end
# :nocov:
