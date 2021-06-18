require_relative 'zenodo/stats'

namespace :zenodo do
  desc 'Queue feeder that keeps migration items going to the delayed job queue with sleep in between'
  task feed_queue: :environment do
    trap('SIGINT') do
      puts 'Exiting zenodo feeder'
      exit
    end

    # try to only fill the queue to this level, will be re-filled frequently, anyway
    max_feed_queue = 8

    sql = <<~SQL.strip
      SELECT ids.* FROM stash_engine_identifiers ids
        LEFT JOIN (SELECT id, identifier_id FROM stash_engine_zenodo_copies WHERE copy_type = 'data') cops
        ON ids.id = cops.identifier_id
      WHERE ids.pub_state = 'published'
        AND cops.id IS NULL
        AND ids.storage_size < 1e+10
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
    elapsed = Time.new - Zenodo::Stats.first_migration
    count_migrated = Zenodo::Stats.count_migrated
    count_remaining = Zenodo::Stats.count_remaining
    size_migrated = Zenodo::Stats.size_migrated
    size_remaining = Zenodo::Stats.size_remaining

    bytes_per_second = size_migrated / elapsed

    time_remaining = size_remaining / bytes_per_second

    puts "#{count_migrated} of #{count_migrated + count_remaining} old datasets have been replicated"
    puts "#{format('%.2f', (count_migrated.to_f / (count_migrated + count_remaining) * 100))}% by number of old datasets have been replicated"

    puts "#{StashEngine::ApplicationController.helpers.filesize(size_migrated)} of " \
        "#{StashEngine::ApplicationController.helpers.filesize(size_remaining + size_migrated)} of the old datasets have been replicated"

    puts "#{format('%.2f', (size_migrated.to_f / (size_remaining + size_migrated) * 100))}% complete by size"

    puts "Optimistic completion date: #{(Time.new + time_remaining).strftime('%Y-%m-%d')}"
  end
end
