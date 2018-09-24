FactoryBot.define do
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
end
