module StashEngine
  class ResourceState < ActiveRecord::Base
    belongs_to :user
    belongs_to :resource
    include StashEngine::Concerns::ResourceUpdated

    enum resource_state: %w[in_progress processing submitted error].map { |i| [i.to_sym, i] }.to_h
    validates :resource_state, presence: true

    after_save :sync_curation_activity

    private

    # Add a record to the CurationActivities for the Resource IF the new resource_state
    # is 'submitted' or 'in_progress' and that is not already the current curation status
    def sync_curation_activity
      return unless %w[in_progress submitted].include?(resource_state)
      return if resource.latest_curation_status&.status == resource_state
      StashEngine::CurationActivity.create(resource: resource, user: user, status: resource_state)
    end
  end
end
