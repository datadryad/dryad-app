FactoryBot.define do
  factory(:file_upload, class: StashEngine::FileUpload) do
    id { nil }
    upload_file_name { 'test.txt' }
    upload_content_type { 'text/plain' }
    upload_file_size { 12_345 }
    resource_id { nil }
    temp_file_path { '/home/ubuntu/dryad/uploads/25/test.txt' }
    file_state { 'created' }
    url { 'http://example.org/test.txt' }
    status_code { 200 }
    timed_out { 0 }
    original_url { nil }
    cloud_service { nil }
    digest { '7597d11c020ee3d160a8b55a44471aff' }
    digest_type { 'md5' }
    description { 'We motivate the need for gigabit switches with this log.' }
  end
end
