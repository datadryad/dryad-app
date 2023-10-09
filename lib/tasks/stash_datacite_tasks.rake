# :nocov:
namespace :stash_datacite do

  desc 'Convert old publicationDOI records from InternalDatum into RelatedIdentifiers'
  task internal_data_to_related_identifier: :environment do
    StashEngine::InternalDatum.joins(stash_identifier: :resources)
      .includes(stash_identifier: :resources)
      .where(data_type: 'publicationDOI').each do |internal_datum|
      next unless internal_datum.value.present?

      resource = internal_datum.stash_identifier.latest_resource
      next unless resource.present?

      related_identifier = StashDatacite::RelatedIdentifier.find_or_create_by(resource_id: resource.id,
                                                                              related_identifier_type: 'doi',
                                                                              work_type: 'primary_article')

      next if related_identifier.related_identifier.present?

      related_identifier.update(related_identifier: internal_datum.value,
                                relation_type: 'iscitedby',
                                hidden: false)

    end
    StashEngine::InternalDatum.where(data_type: 'publicationDOI').destroy_all
  end

end
# :nocov:
