module StashEngine
  module MetadataEntryPagesHelper
    def duplicate_resource
      begin
        @new_res = @resource.amoeba_dup
        @new_res.current_editor_id = current_user&.id
        @new_res.save
        # binding.pry
        pp @new_res.authors.first.errors.messages
        pp @new_res.errors.messages
        @new_res.save!
      rescue ActiveRecord::RecordNotUnique
        @resource.identifier.reload
        @new_res = @resource.identifier.latest_resource unless @resource.identifier.latest_resource_id == @resource.id
        @new_res ||= @resource.amoeba_dup
        @new_res.current_editor_id = current_user&.id
        @new_res.save!
      end
      # The default curation activity gets set to the `Resource.user_id` but we want to use the current user here
      @new_res.curation_activities.update_all(user_id: current_user&.id)
      @new_res.data_files.each(&:populate_container_files_from_last)
    end
  end
end
