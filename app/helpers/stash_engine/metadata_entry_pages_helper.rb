module StashEngine
  module MetadataEntryPagesHelper
    def duplicate_resource
      @new_res = @resource.amoeba_dup
      @new_res.current_editor_id = current_user&.id
      # The default curation activity gets set to the `Resource.user_id` but we want to use the current user here
      @new_res.curation_activities.update_all(user_id: current_user&.id)
      @new_res.save!
    end
  end
end
