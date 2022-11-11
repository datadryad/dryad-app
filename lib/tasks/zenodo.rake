require_relative 'zenodo/stats'
require_relative 'zenodo/metadata'
require 'byebug'

namespace :zenodo do
  desc 'Queue feeder that keeps migration items going to the delayed job queue with sleep in between'
  task feed_queue: :environment do
    trap('SIGINT') do
      puts 'Exiting zenodo feeder'
      exit
    end

    # try to only fill the queue to this level, will be re-filled frequently, anyway
    max_feed_queue = 1 # only start another long (50GB+) when nothing much is happening since these take forever, don't monopolize queue

    sql = <<~SQL.strip
      SELECT ids.* FROM stash_engine_identifiers ids
        LEFT JOIN (SELECT id, identifier_id FROM stash_engine_zenodo_copies WHERE copy_type = 'data') cops
        ON ids.id = cops.identifier_id
      WHERE ids.pub_state = 'published'
        AND cops.id IS NULL
        AND ids.storage_size > 5e+10
      ORDER BY RAND()
      LIMIT #{max_feed_queue};
    SQL

    loop do
      puts Time.new.iso8601
      StashEngine::Identifier.find_by_sql(sql).each do |identifier|
        break if Delayed::Job.count >= max_feed_queue

        resource = identifier.latest_resource_with_public_download
        resource&.send_to_zenodo(note: 'Sent by migration')

        # set retries to 10 so our daily retries for old migrations don't overwhelm current items and we can retry manually
        ZenodoCopy.where(resource_id: resource.id, copy_type: 'data').update(retries: 10)
        puts "  inserting #{identifier}"
        sleep 0.5
      end
      sleep 30
    end
  end

  desc 'Gives stats for the zenodo replication of old datasets'
  task migration_stats: :environment do

    puts 'Stats for old datasets being copied to Zenodo--excludes items already sent since we began replicating'
    elapsed = Time.new - Tasks::Zenodo::Stats.first_migration
    count_migrated = Tasks::Zenodo::Stats.count_migrated
    count_remaining = Tasks::Zenodo::Stats.count_remaining
    size_migrated = Tasks::Zenodo::Stats.size_migrated
    size_remaining = Tasks::Zenodo::Stats.size_remaining

    bytes_per_second = size_migrated / elapsed

    time_remaining = size_remaining / bytes_per_second

    puts "#{count_migrated} of #{count_migrated + count_remaining} old datasets have been replicated"
    puts "#{format('%.2f', (count_migrated.to_f / (count_migrated + count_remaining) * 100))}% by number of old datasets have been replicated"

    puts "#{StashEngine::ApplicationController.helpers.filesize(size_migrated)} of " \
         "#{StashEngine::ApplicationController.helpers.filesize(size_remaining + size_migrated)} of the old datasets have been replicated"

    puts "#{format('%.2f', (size_migrated.to_f / (size_remaining + size_migrated) * 100))}% complete by size"

    puts "Optimistic completion date: #{(Time.new + time_remaining).strftime('%Y-%m-%d')}"
  end

  desc 'Update metadata at zenodo latest version for datasets'
  task update_metadata: :environment do
    $stdout.sync = true # keeps the output from buffering and delaying output

    trap('SIGINT') do
      puts 'Exiting metadata update'
      exit
    end

    start_num = ARGV[1].to_i
    identifiers = StashEngine::Identifier.joins(:zenodo_copies).distinct.order(:id).offset(start_num)

    # rubocop:disable Style/BlockDelimiters
    ARGV.each { |a| task a.to_sym do; end } # prevents rake from interpreting addional args as other rake tasks
    # rubocop:enable Style/BlockDelimiters

    puts "Updating zenodo metadata starting at record #{start_num}"

    # this stops spamming of activerecord query logs in dev environment
    ActiveRecord::Base.logger.silence do
      identifiers.each_with_index do |identifier, idx|
        data = identifier.zenodo_copies.where(state: 'finished').where('deposition_id IS NOT NULL')
          .where("copy_type like 'data%'").order(id: :desc).first
        supp = identifier.zenodo_copies.where(state: 'finished').where('deposition_id IS NOT NULL')
          .where("copy_type like 'supp%'").order(id: :desc).first
        sfw = identifier.zenodo_copies.where(state: 'finished').where('deposition_id IS NOT NULL')
          .where("copy_type like 'software%'").order(id: :desc).first

        # Was going to output every 50th item so we can see it's still going without spamming every item to the output.
        # However the updates to zenodo are slow enough that it probably makes sense to see each and write log to
        # examine later.
        puts "updating number #{idx + start_num} with identifier.id #{identifier.id}: #{identifier.identifier}" # if idx % 50 == 0

        begin
          Tasks::Zenodo::Metadata.new(zenodo_copy: data).update_metadata if data.present?
          Tasks::Zenodo::Metadata.new(zenodo_copy: supp).update_metadata if supp.present?
          Tasks::Zenodo::Metadata.new(zenodo_copy: sfw).update_metadata if sfw.present?
        rescue Stash::ZenodoReplicate::ZenodoError => e
          puts "Error updating metadata:\n#{e}\n\n"
        end
        sleep 1
      end
    end
  end
end
