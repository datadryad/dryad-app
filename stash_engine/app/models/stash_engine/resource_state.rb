module StashEngine
  class ResourceState < ActiveRecord::Base
    belongs_to :user
    belongs_to :resource
    include StashEngine::Concerns::ResourceUpdated

    enum resource_state: %w[in_progress processing submitted error].map { |i| [i.to_sym, i] }.to_h
    validates :resource_state, presence: true

    after_save :sync_curation_activity!

    private

    # Add a record to the CurationActivities for the Resource IF the new resource_state
    # is 'submitted' or 'in_progress' and that is not already the current curation status
    # But don't create the curation_activity if preserve_curation_status is set, because a user who has
    # set that flag is expecting the curation_status to remain as whatever they have already set.
    def sync_curation_activity!
      return if resource.preserve_curation_status
      return unless %w[in_progress submitted].include?(resource_state)
      return if resource.current_curation_activity&.status == resource_state
      StashEngine::CurationActivity.create(resource: resource, user: user, status: resource_state)
    end
  end
end
