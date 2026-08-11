require 'csv'

# run from console: Reports::DatasetAgeByStatus.new.generate
module Reports
  class DatasetAgeByStatus

    attr_reader :status, :datetime

    def initialize(status, date)
      @status = status
      @datetime = date.to_datetime.beginning_of_day
      @filename = "#{Rails.env}/volume_and_age/datasets-in-#{status}-on-#{@datetime.to_date}.csv"
    end

    def generate
      file_contents = CSV.generate do |row|
        row << ['Identifier ID', 'DOI', 'Last status date', 'Age (day)']
        in_status_on_date.includes(:identifier, { resource: :process_date }).find_each do |ca|
          entered_in_status = ca.resource.process_date.last_status_date
          age_in_status = TimeInStatus.new(return_in: 'days').readable_time(datetime.to_i - entered_in_status.to_i)
          row << [ca.identifier_id, ca.identifier.identifier, ca.resource.process_date.last_status_date, age_in_status]
        end
      end
      upload_to_s3(file_contents)
    end

    private

    def in_status_on_date
      latest_per_identifier = StashEngine::CurationActivity.with_deleted.select('identifier_id, MAX(id) AS last_ca_id')
        .where(created_at: ..datetime)
        .group('identifier_id')

      StashEngine::CurationActivity
        .joins("inner join (#{latest_per_identifier.to_sql}) as latest on stash_engine_curation_activities.id=last_ca_id")
        .where(status: status, created_at: ..datetime)
        .limit(3).offset(1000)
    end

    def upload_to_s3(file_contents)
      Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG.s3.reports_bucket)
        .put(s3_key: @filename, contents: file_contents)
      Report.create(
        title: "Datasets age by status",
        bucket: APP_CONFIG.s3.reports_bucket,
        s3_key: @filename,
        time: datetime,
        status: status,
        report_type: Report.report_types[:age_by_status]
      )
    end
  end
end
