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
end
