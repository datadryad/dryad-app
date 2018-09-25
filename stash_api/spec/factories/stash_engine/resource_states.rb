FactoryBot.define do
  factory(:resource_state, class: StashEngine::ResourceState) do
    user_id { nil }
    resource_state { 'in_progress' }
    resource_id { nil }
  end
end
