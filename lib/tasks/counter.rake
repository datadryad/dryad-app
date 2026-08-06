require 'net/scp'

namespace :counter do
  # this allows stats to be zeroed without destroying citation count which happens in another process and means that our
  # stats can be manually rebuilt from our full JSON stat files which DataCite doesn't accept for unknown reasons.
  desc "zero out table of cached Counter stats without affecting citation count which doesn't come from counter"
  task clear_cache: :environment do
    StashEngine::CounterStat.in_batches.update_all(unique_investigation_count: 0, unique_request_count: 0)
  end

  desc 'task to populate in citation information that has not been cached'
  task populate_citations: :environment do
    puts "Run to update citations at #{Time.new}"
    count = StashEngine::Identifier.where(pub_state: %i[published embargoed]).count

    StashEngine::Identifier.where(pub_state: %i[published embargoed]).find_each.with_index do |identifier, idx|
      puts "Updated #{idx + 1}/#{count}" if (idx + 1) % 100 == 0

      counter_stat = identifier.counter_stat
      next if counter_stat.citation_updated > 30.days.ago # only do this expensive operation once a month, so skip if it's been checked lately

      # identifier.citations automatically checks and caches new ones as needed
      citations = identifier.citations
      counter_stat.citation_count = citations.length
      counter_stat.citation_updated = Time.new
      counter_stat.save!
      sleep 1 if (idx + 1) % 10 == 0 # to avoid overloading DataCite hub
    end
    puts "Completed populating citations at #{Time.new.utc.iso8601}"
  end
end
