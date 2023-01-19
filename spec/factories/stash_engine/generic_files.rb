FactoryBot.define do

  factory :generic_file, class: StashEngine::GenericFile do
    resource

    upload_file_name { File.basename(Faker::File.file_name) }
    upload_content_type { Faker::File.mime_type }
    upload_file_size { Faker::Number.between(from: 1, to: 100_000_000) }
    file_state { 'created' }
    type { %w[StashEngine::DataFile StashEngine::SoftwareFile StashEngine::SuppFile][rand(3)] }
  end
end
