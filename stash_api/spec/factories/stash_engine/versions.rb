FactoryBot.define do
  factory(:version, class: StashEngine::Version) do
    version { 1 }
    resource_id { nil }
    merritt_version { 1 }
  end
end
