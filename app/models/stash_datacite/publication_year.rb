# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_publication_years
#
#  id               :integer          not null, primary key
#  publication_year :string(191)
#  resource_id      :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
module StashDatacite
  class PublicationYear < ApplicationRecord
    self.table_name = 'dcs_publication_years'
    belongs_to :resource, class_name: StashEngine::Resource.to_s

    def self.ensure_pub_year(resource)
      return if resource.publication_years.exists?

      create(publication_year: Time.now.utc.year, resource_id: resource.id)
    end
  end
end
