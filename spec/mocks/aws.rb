module Mocks

  module Aws

    def mock_aws!
      mock_s3!
    end

    # rubocop:disable Metrics/AbcSize
    def mock_s3!
      allow_any_instance_of(::Aws::S3::Object).to receive(:delete).and_return(nil)
      allow_any_instance_of(::Aws::S3::Object).to receive(:exists?).and_return(nil)
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
    # rubocop:enable Metrics/AbcSize

  end

end
