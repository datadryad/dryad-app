FactoryBot.define do
  factory :container_file, class: StashEngine::ContainerFile do
    data_file

    path { Faker::File.file_name }
    mime_type { Faker::File.mime_type }
    size { Faker::Number.between(from: 1, to: 100_000_000) }
  end
end