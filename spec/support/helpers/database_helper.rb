# this is a helper to create states in the database for seeing specific display states, mostly on the landing page responses

module DatabaseHelper

  def create_basic_dataset!
    @user = create(:user, role: 'superuser')
    @identifier = create(:identifier)
    @resource = create(:resource, :submitted, identifier: @identifier, user_id: @user.id, tenant_id: @user.tenant_id,
                                              authors: [create(:author)], descriptions: [create(:description)],
                                              stash_version: create(:version, version: 1, merritt_version: 1),
                                              data_files: [create(:data_file)])
  end

  # this essentially creates a new resource (version) to start working on for a user
  def duplicate_resource!(resource:, user: nil)
    new_res = resource.amoeba_dup
    new_res.current_editor_id = (user ? user.id : resource.user_id)

    new_res.curation_activities.update_all(user_id: user.id) if user
    new_res.save!
  end

  def create_data_file(resource_id)
    StashEngine::DataFile.create(
      {
        original_filename: Faker::File.file_name(dir: '', directory_separator: ''),
        resource_id: resource_id,
        upload_file_name: 'example_data_file.csv',
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created'
      }
    )
  end

  def create_software_file(resource_id)
    StashEngine::SoftwareFile.create(
      {
        original_filename: Faker::File.file_name(dir: '', directory_separator: ''),
        resource_id: resource_id,
        upload_file_name: 'example_software_file.csv',
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created'
      }
    )
  end

  def create_supplemental_file(resource_id)
    StashEngine::SuppFile.create(
      {
        original_filename: Faker::File.file_name(dir: '', directory_separator: ''),
        resource_id: resource_id,
        upload_file_name: 'example_supp_file.csv',
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created'
      }
    )
  end
end
