# frozen_string_literal: true

module StashDatacite
  class PublicationYear < ActiveRecord::Base
    self.table_name = 'dcs_publication_years'
    belongs_to :resource, class_name: StashEngine::Resource.to_s
    include StashEngine::Concerns::ResourceUpdated

    def self.ensure_pub_year(resource)
      return if resource.publication_years.exists?
      create(publication_year: Time.now.utc.year, resource_id: resource.id)
    end
  end
end
