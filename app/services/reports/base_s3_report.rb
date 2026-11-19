module Reports
  module BaseS3Report

    def upload_to_s3(file_contents, file_key, s3_bucket_name: APP_CONFIG.s3.reports_bucket)
      Stash::Aws::S3.new(s3_bucket_name: s3_bucket_name)
        .put(s3_key: file_key, contents: file_contents)
      true
    rescue Aws::S3::Errors::ServiceError => e
      pp "ERROR: #{e.message}"
      false
    end
  end
end
