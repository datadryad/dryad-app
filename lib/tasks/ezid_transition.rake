require 'csv'
require 'tasks/ezid_transition/register'
namespace :ezid_transition do

  # this will find ezid datasets over 1 year old that are not submitted and remove them, set RAILS_ENV=production
  # for real removals from production
  desc 'Remove old unsubmitted datasets over a year old from EZID shoulders'
  task remove_old_unsubmitted: :environment do

    stash_ids = StashEngine::Identifier.where('created_at < ?', 1.year.ago)
      .where("identifier NOT LIKE '10.5061%' and identifier NOT LIKE '10.15146%'")

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

  # test id doi:10.6078/D1BB16
  desc 'Makes csv of EZID status reserved/registered for all EZID identifiers'
  task ezid_status: :environment do
    filename = "ezid_dryad_identifiers_#{Time.now.iso8601}.csv"
    CSV.open(filename, 'w') do |csv|
      csv << %w[identifier pub_state ezid_status tenant_id]
      stash_ids = StashEngine::Identifier.where("identifier NOT LIKE '10.5061%' and identifier NOT LIKE '10.15146%'")
      stash_ids.each_with_index do |stash_id, idx|

        attempts ||= 1
        resp = HTTP.accept('text/plain').timeout(15).get("https://ezid.cdlib.org/id/doi:#{stash_id.identifier}")
        ezid_status = if resp.status == 200
                        ezid_info = resp.body.to_s
                        ezid_info.match(/^_status: (\S+)$/)[1]
                      elsif resp.status == 400
                        'not_found'
                      end

        puts "#{idx}/#{stash_ids.length} #{stash_id.identifier},#{stash_id.pub_state},#{ezid_status}"
        csv << [stash_id.identifier, stash_id.pub_state, ezid_status, stash_id&.resources&.first&.tenant_id]
        sleep 0.25
      rescue StandardError => e
        if (attempts += 1) < 5
          sleep 10
          puts "  retrying #{stash_id.identifier} attempt #{attempts} with error #{e.message}"
          retry # ⤴
        end
      end
    end
    puts "file written to #{filename}"
  end

  desc 'Updates from list of DOIs to change reserved to registered in EZID'
  task registered: :environment do
    $stdout.sync = true

    unless ENV['RAILS_ENV'] && ENV['DOI_FILE']
      puts 'RAILS_ENV must be explicitly set before running this script (such as production)'
      puts 'Also set environment variable DOI_FILE to the file that contains the DOIs to update with placeholder data.'
      puts 'These should be EZID DOIs to pre-populate with data so they are more than reserved and can be moved to DataCite.'
      puts ''
      puts 'Example:'
      puts 'RAILS_ENV=development DOI_FILE="spec/fixtures/ezid_doi_examples.txt" bundle exec rails ezid_transition:registered'
      puts ''
      puts 'The file with lists of DOIs should be one per line and be bare DOIs like 10.5072/FK2HT2SM2K.'
      puts 'You can check DOIs at urls like https://ezid.cdlib.org/id/doi:10.5072/FK2HT2SM2K'
      next
    end

    File.foreach(ENV.fetch('DOI_FILE', nil)).with_index do |doi, idx|
      doi.strip!
      next if doi.blank?

      puts "#{idx} -- #{doi}"
      # sorry, I couldn't figure out how to stop the EZID gem from printing to stdout, even setting logggers and other things
      Tasks::EzidTransition::Register.register_doi(doi: doi)
    end
    puts 'Done'
  end
end
