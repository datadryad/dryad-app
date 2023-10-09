# :nocov:
namespace :rsolr do

  desc 'Reindex the identifier/resource records in Geoblacklight'
  task reindex: :environment do # loads rails environment
    p 'Resubmitting Dataset information to Geoblacklight for datasets with published metadata.'
    ids = StashEngine::Identifier.all.publicly_viewable
    ids.each_with_index do |identifier, idx|
      puts "#{idx + 1}/#{ids.count} processed" if ((idx + 1) % 500) == 0 # only output progress occasionally, but good to know it's working
      next if identifier.resources.submitted&.by_version_desc&.first.nil?

      identifier.latest_resource_with_public_metadata&.submit_to_solr
    end
    p 'Complete'
  end

end
# :nocov:
