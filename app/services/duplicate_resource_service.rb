class DuplicateResourceService
  attr_reader :resource, :user
  def initialize(resource, user)
    @resource = resource
    @user = user
  end

  def call
    begin
      new_res = build_new_resource
      new_res.save!
    rescue ActiveRecord::RecordNotUnique
      resource.identifier.reload
      new_res = resource.identifier.latest_resource unless resource.identifier.latest_resource_id == resource.id
      new_res ||= build_new_resource
      new_res.save!
    end

    new_res.curation_activities.update_all(user_id: user.id)
    new_res.data_files.each(&:populate_container_files_from_last)
    new_res
  end

  private

  def build_new_resource
    res = resource.amoeba_dup
    res.current_editor_id = user.id
    res
  end
end
