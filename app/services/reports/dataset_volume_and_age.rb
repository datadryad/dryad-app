# :nocov:
require 'csv'

# run from console: Reports::DatasetVolumeAndAge.new.generate
module Reports
  class DatasetVolumeAndAge
    include BaseS3Report

    attr_reader :status, :datetime

    def initialize(status, date)
      @status = status
      @datetime = date.to_datetime.end_of_day
      @file_path = "#{Rails.env}/volume_and_age/datasets-in-#{status}-on-#{@datetime.to_date}.csv"
    end

    def generate
      file_contents = CSV.generate do |csv|
        csv << ['Identifier ID', 'DOI', 'Last status date', 'Age (day)']
        in_status_on_date.includes(:identifier, { resource: :process_date }).find_each do |ca|
          entered_in_status = ca.resource.process_date.last_status_date
          age_in_status = TimeInStatus.new(return_in: 'days').readable_time(datetime.to_i - entered_in_status.to_i)
          csv << [ca.identifier_id, ca.identifier.identifier, ca.resource.process_date.last_status_date, age_in_status]
        end
      end
      upload_to_s3(file_contents, @file_path)
      create_report_record
    end

    private

    def in_status_on_date
      latest_per_identifier = StashEngine::CurationActivity.with_deleted.select('identifier_id, MAX(id) AS last_ca_id')
        .where(created_at: ..datetime)
        .group('identifier_id')

      StashEngine::CurationActivity
        .joins("inner join (#{latest_per_identifier.to_sql}) as latest on stash_engine_curation_activities.id=last_ca_id")
        .where(status: status, created_at: ..datetime)
    end

    def create_report_record
      Report.create(
        title: 'Datasets volume and age',
        bucket: APP_CONFIG.s3.reports_bucket,
        s3_key: @file_path,
        time: datetime,
        status: status,
        report_type: Report.report_types[:volume_and_age]
      )
    end
  end
end
# :nocov:
