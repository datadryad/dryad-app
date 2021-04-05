FactoryBot.define do
  factory(:data_file, class: StashEngine::DataFile) do
    id { nil }
    upload_file_name { 'test.txt' }
    upload_content_type { 'text/plain' }
    upload_file_size { 12_345 }
    resource_id { nil }
    file_state { 'created' }
    url { 'http://example.org/test.txt' }
    status_code { 200 }
    timed_out { 0 }
    original_url { nil }
    cloud_service { nil }
  end

  factory(:identifier, class: StashEngine::Identifier) do
    identifier { '138/238/2238' }
    identifier_type { 'DOI' }
  end

  factory(:curation_activity, class: StashEngine::CurationActivity) do
    status { 'submitted' }
  end

  factory(:resource_state, class: StashEngine::ResourceState) do
    user_id { nil }
    resource_state { 'in_progress' }
    resource_id { nil }
  end

  factory(:resource, class: StashEngine::Resource) do
    user_id { nil }
    current_resource_state_id { nil }
    has_geolocation { 0 }
    identifier_id { nil }
    title { 'My Cats Have Fleas' }
    current_editor_id { nil }
    tenant_id { 'exemplia' }
    skip_datacite_update { false }
  end

  factory(:user, class: StashEngine::User) do
    first_name { 'Juanita' }
    last_name { 'Collins' }
    email { 'juanita.collins@example.org' }
    tenant_id { 'exemplia' }
    role { 'user' }
    orcid { '1111-2222-3333-4444' }
    migration_token { 'xxxxxx' }
    old_dryad_email { 'lolinda@example.com' }
    eperson_id { 37 }
  end

  factory(:version, class: StashEngine::Version) do
    version { 1 }
    resource_id { nil }
    merritt_version { 1 }
  end
end
