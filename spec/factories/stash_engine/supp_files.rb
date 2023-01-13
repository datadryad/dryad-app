FactoryBot.define do

  factory :supp_file, class: StashEngine::SuppFile do
    resource

    upload_file_name { File.basename(Faker::File.file_name) }
    upload_content_type { Faker::File.mime_type }
    upload_file_size { Faker::Number.between(from: 1, to: 100_000_000) }
    file_state { 'created' }
  end
end
