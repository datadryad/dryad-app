module StashEngine
  class DeleteDatasetsService
    attr_reader :resource, :current_user

    def initialize(resource, current_user = nil)
      @resource = resource
      @current_user = current_user
    end

    def call
      last = resource.previous_resource
      if last
        user_id = current_user&.id || 0
        note = "#{(user_id == 0 && 'System cleanup') || 'User'} deleted unsubmitted version #{resource.version_number}"
        StashEngine::CurationActivity.create(resource_id: last.id, status: last.current_curation_status, user_id: user_id, note: note)
        resource.create(resource_id: last.id, status: last.current_curation_status, user_id: user_id, note: note)
      end
      success = resource.destroy
      last.identifier.update(latest_resource_id: last.id) if success && last.identifier

      success
    end
  end
end
