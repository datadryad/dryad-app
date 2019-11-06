FactoryBot.define do

  factory :version, class: StashEngine::Version do
    resource
    version { 1 }
    merritt_version { 1 }
    zip_filename { nil }
  end
end
