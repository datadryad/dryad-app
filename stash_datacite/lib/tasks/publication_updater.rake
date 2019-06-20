require 'stash/import/crossref'

namespace :publication_updater do

  desc 'Testing Publication Updater'
  task test: :environment do
    #StashEngine::InternalDatum.where(data_type: 'publicationISSN').select(:value).distinct.limit(5).each do |issn|
    #  ::Stash::Import::Crossref.query_for_issn(issn: issn.value)
    #end

    dois = StashEngine::InternalDatum.where(data_type: 'publicationDOI').pluck(:value).uniq.first
    Stash::Import::Crossref.query_for_dois(dois: dois)
  end

end