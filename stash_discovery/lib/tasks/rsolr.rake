namespace :rsolr do

  desc 'Reindex the identifier/resource records in Geoblacklight'
  task reindex: :environment do # loads rails environment
    p 'Resubmitting Dataset information to Geoblacklight for datasets with published metadata.'
    StashEngine::Identifier.includes(:internal_data, :latest_resource).all.each do |identifier|
      next unless identifier.latest_resource.metadata_published?
      identifier.latest_resource.submit_to_solr
    end
    p 'Complete'
  end

end
