# this is a helper to create states in the database for seeing specific display states, mostly on the landing page responses

module DatabaseHelper

  def create_basic_dataset!
    resource = create(:resource, :submitted, created_at: 1.minute.ago, authors: 3.times.map { create(:author) })
    3.times.map { create(:data_file, resource: resource) }
    create(:description, resource: resource, description_type: 'technicalinfo')
    create(:description, resource: resource, description_type: 'usage_notes', description: nil)
    resource
  end

  # this essentially creates a new resource (version) to start working on for a user
  def duplicate_resource!(resource:, user: nil)
    new_res = resource.amoeba_dup
    new_res.current_editor_id = (user ? user.id : resource.submitter.id)

    new_res.curation_activities.update_all(user_id: user.id) if user
    new_res.save!
  end

  # TODO: this will replace the others 3 below
  def create_generic_file(resource_id)
    filename = Faker::File.file_name(dir: '', directory_separator: '')
    StashEngine::GenericFile.create(
      {
        original_filename: filename,
        download_filename: filename,
        upload_file_name: filename,
        resource_id: resource_id,
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created',
        type: %w[StashEngine::DataFile StashEngine::SoftwareFile StashEngine::SuppFile][rand(3)]
      }
    )
  end

  # TODO: make only one method to create generic files
  def create_data_file(resource_id)
    filename = Faker::File.file_name(dir: '', directory_separator: '')
    StashEngine::DataFile.create(
      {
        original_filename: filename,
        download_filename: filename,
        upload_file_name: filename,
        resource_id: resource_id,
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created'
      }
    )
  end

  def create_software_file(resource_id)
    filename = Faker::File.file_name(dir: '', directory_separator: '')
    StashEngine::SoftwareFile.create(
      {
        original_filename: filename,
        download_filename: filename,
        upload_file_name: filename,
        resource_id: resource_id,
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created'
      }
    )
  end

  def create_supplemental_file(resource_id)
    filename = Faker::File.file_name(dir: '', directory_separator: '')
    StashEngine::SuppFile.create(
      {
        original_filename: filename,
        download_filename: filename,
        upload_file_name: filename,
        resource_id: resource_id,
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        status_code: 200,
        file_state: 'created'
      }
    )
  end
end
