require 'stash/import/crossref'

namespace :publication_updater do

  desc 'Testing Publication Updater'
  task test: :environment do
    # StashEngine::InternalDatum.where(data_type: 'publicationISSN').select(:value).distinct.limit(5).each do |issn|
    #  ::Stash::Import::Crossref.query_for_issn(issn: issn.value)
    # end

    identifiers = StashEngine::Identifier.publicly_viewable.order(created_at: :desc).limit(15)

    identifiers = identifiers.map do |identifier|
      {
        identifier: identifier,
        doi: identifier.internal_data.where(data_type: 'publicationDOI').where.not(value: nil).first&.value
      }
    end
    identifiers.select { |hash| hash[:doi].present? }.each do |hash|
      p "Searching for: #{hash[:doi]}"

      p Stash::Import::Crossref.query_by_doi(identifier: hash[:identifier], doi: hash[:doi])
    end
  end

end
