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
  end
end
