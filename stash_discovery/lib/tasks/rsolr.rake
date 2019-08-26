namespace :rsolr do

  desc 'Reindex the identifier/resource records in Geoblacklight'
  task reindex: :environment do # loads rails environment
    p 'Resubmitting Dataset information to Geoblacklight for datasets with published metadata.'
    ids = StashEngine::Identifier.includes(:internal_data, :latest_resource).all
    ids.each_with_index do |identifier, idx|
      puts "#{idx + 1}/#{ids.count} processed" if ((idx + 1) % 500) == 0 # only output progress occasionally, but good to know it's working
      next unless identifier.latest_resource.metadata_published?
      identifier.latest_resource.submit_to_solr
    end
    p 'Complete'
  end

end
