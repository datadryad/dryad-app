module StashEngine
  class DeleteDatasetsService
    attr_reader :resource, :current_user, :add_delete_note

    def initialize(resource, current_user: nil, add_delete_note: true)
      @resource = resource
      @current_user = current_user
      @add_delete_note = add_delete_note
    end

    def call
      prev = resource.previous_resource
      if prev && add_delete_note
        user_id = current_user&.id || 0
        note = "#{(user_id == 0 && 'System cleanup') || 'User'} deleted unsubmitted version #{resource.version_number}"
        StashEngine::CurationActivity.create(resource_id: prev.id, status: prev.current_curation_status, user_id: user_id, note: note)
      end
      resource.destroy
    end
  end
end
