module Mocks

  module Aws

    def mock_aws!
      mock_s3!
      mock_multipart_api_upload!
    end

    def mock_s3!
      allow_any_instance_of(::Aws::S3::Object).to receive(:delete).and_return(nil)
      allow_any_instance_of(::Aws::S3::Object).to receive(:exists?).and_return(true)
      allow_any_instance_of(::Aws::S3::Object).to receive(:put).and_return(nil)
      allow_any_instance_of(::Aws::S3::Object).to receive(:presigned_url).and_return(
        "https://somebucket.amazonaws.com/presignedURL-#{Faker::Alphanumeric.alphanumeric(number: 10)}"
      )
      allow_any_instance_of(::Aws::S3::Object).to receive(:size).and_return(Faker::Number.number(digits: 6))
      allow_any_instance_of(::Aws::S3::Object).to receive(:upload_stream).and_return(nil)
      allow_any_instance_of(::Aws::S3::ObjectSummary::Collection).to receive(:batch_delete!).and_return(nil)

      # Add a default database configuration, which is needed by Resource.s3_dir_name
      allow(Rails).to receive(:configuration).and_return(OpenStruct.new(database_configuration: { 'test' => { 'host' => 'localhost' } }))
    end

    def mock_multipart_api_upload!
      allow_any_instance_of(::Aws::S3::Client).to receive_message_chain(:create_multipart_upload, :upload_id).and_return('multipart_upload_id')
      allow_any_instance_of(::Aws::S3::Client).to receive(:complete_multipart_upload).and_return(true)
      allow_any_instance_of(::Aws::S3::Client).to receive_message_chain(:head_object, :content_length).and_return(5_000)
      allow_any_instance_of(::Aws::S3::Client).to receive(:abort_multipart_upload).and_return(true)
    end
  end

end
