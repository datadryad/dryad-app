FactoryBot.define do

  factory :file_upload, class: StashEngine::FileUpload do
    resource

    upload_file_name { ::File.basename(Faker::File.file_name) }
    upload_content_type { Faker::File.mime_type }
    upload_file_size { Faker::Number.between(1, 100_000_000) }
    temp_file_path { Faker::File.file_name }
    file_state { 'created' }
  end
end
