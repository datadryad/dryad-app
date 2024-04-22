# :nocov:
namespace :versioning do
  desc 'write sensible versioning display flags and current dataset status'
  task set_view_versions: :environment do
    puts 'Processing . . .'
    count = StashEngine::Identifier.count
    StashEngine::Identifier.find_each.with_index do |identifier, idx|
      # show some progress, so we know something is happening, but don't spam us with all the identifier updates
      puts "Processing #{idx + 1} of #{count}" if (idx + 1) % 100 == 0

      begin
        identifier.update(pub_state: identifier.calculated_pub_state) # set the publishing state explicitly based on pub history
        identifier.fill_resource_view_flags
      rescue StandardError => e
        # this is so we can at least output which identifier caused this exception
        puts "#{identifier.identifier} caused error #{e}"
        raise e
      end
    end
  end
end
# :nocov:
