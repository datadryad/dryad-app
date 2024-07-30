# frozen_string_literal: true

class AddResourcePublications < ActiveRecord::Migration[7.0]
  def up
    ids = StashEngine::Identifier.joins(:latest_resource, :internal_data).where(internal_data: {data_type: ['publicationISSN', 'publicationName', 'manuscriptNumber']}).distinct
    ids.find_each do |id|
      id.resources.each do |resource|
        StashEngine::ResourcePublication.create(resource_id: resource.id, publication_issn: id.journal_datum&.value&.strip, publication_name: id.journal_name_datum&.value&.strip, manuscript_number: id.manuscript_datum&.value&.strip)
      end
    end
  end

  def down
    StashEngine::Identifier.joins(latest_resource: :resource_publication).find_each do |id|
      pub = id.latest_resource.resource_publication
      id.internal_data << StashEngine::InternalDatum.create(data_type: 'publicationISSN', value: pub.publication_issn) unless id.journal_datum == pub.publication_issn
      id.internal_data << StashEngine::InternalDatum.create(data_type: 'publicationName', value: pub.publication_name) unless id.journal_name_datum == pub.publication_name
      id.internal_data << StashEngine::InternalDatum.create(data_type: 'manuscriptNumber', value: pub.manuscript_number) unless id.manuscript_datum == pub.manuscript_number
    end
  end
end
