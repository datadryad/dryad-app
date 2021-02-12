module Mocks

  module Aws

    def mock_aws!
      mock_s3!
    end

    def mock_s3!
      allow_any_instance_of(::Aws::S3::Object).to receive(:put).and_return(nil)
      allow_any_instance_of(::Aws::S3::Object).to receive(:presigned_url).and_return(
        "https://somebucket.amazonaws.com/presignedURL-#{Faker::Alphanumeric.alphanumeric(number: 10)}"
      )

      # Add a default database configuration, which is needed by Resource.s3_dir_name
      allow(Rails).to receive(:configuration).and_return(OpenStruct.new(database_configuration: { 'test' => { 'host' => 'localhost' } }))
    end

  end

end
