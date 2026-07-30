# == Schema Information
#
# Table name: research_integrity_cases
#
#  id                   :bigint           not null, primary key
#  notes                :text(65535)
#  resolved             :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  curation_activity_id :bigint
#  identifier_id        :bigint
#
class ResearchIntegrityCase < ApplicationRecord
  belongs_to :identifier, class_name: 'StashEngine::Identifier'
  belongs_to :curation_activity, class_name: 'StashEngine::CurationActivity'

  scope :resolved, -> { where(resolved: true) }
  scope :unresolved, -> { where(resolved: false) }

  def resource
    identifier.latest_resource
  end

  def salesforce_links
    Stash::Salesforce.find_cases_by_doi(identifier.identifier)
  end

end
