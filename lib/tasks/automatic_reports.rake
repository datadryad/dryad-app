# :nocov:
namespace :automatic_reports do

  # example: RAILS_ENV=production bundle exec rake automatic_reports:reports_for_date
  desc 'Run automatic reports based on date'
  task reports_by_date: :environment do
    if Date.today.day == 1
      # End of month reports
      pp "Running TATs report for year: #{1.day.ago.year}, month: #{1.day.ago.month}"
      Reports::Tats.new(year: 1.day.ago.year, month: 1.day.ago.month).generate

      %i[in_progress queued curation peer_review action_required].each do |status|
        pp "Running DatasetVolumeAndAge report for status: #{status}, date: #{1.day.ago}"
        Reports::DatasetVolumeAndAge.new(status, 1.day.ago).generate
      end
    end
  end
end
# :nocov:
