require 'byebug'
require 'csv'

module Tasks
  module Reports
    class AuthorReports
      # rubocop:disable Metrics/MethodLength
      def self.repeat_customers

        CSV.open(File.join(Rails.root.join('tmp'), "Repeat_Customers_Report-#{Time.now.strftime('%Y-%m-%d')}.csv"), 'wb') do |csv|
          csv << ['Report', 'Submitters', ' Multiple times Submitters', 'Coauthors', 'Multiple times Coauthors', 'Percent', 'Average']

          # 1. Submitting authors who submitted in the past

          submitters = StashEngine::Resource.latest_per_dataset.group(:user_id).count
          resubmitters = submitters.select { |_k, v| v > 1 }
          percent_of_resubmitters = (resubmitters.count * 100) / submitters.count

          avg_submissions_per_submitter = submitters.values.sum / submitters.count.to_f
          avg_submissions_per_resubmitter = resubmitters.values.sum / resubmitters.count.to_f

          csv << ['Submitting authors who submitted in the past', submitters.count, resubmitters.count, nil, nil, percent_of_resubmitters.round(2)]

          # 2. Submitting authors who coauthored in the past

          submitters_orcid = StashEngine::Resource.latest_per_dataset.joins(:user).distinct.select(:orcid).count
          submitters_as_coauthors = StashEngine::Author.joins(resource: :user).
            where('stash_engine_authors.author_orcid in (?)', StashEngine::Resource.latest_per_dataset.joins(:user).distinct.select(:orcid)).
            where('orcid != author_orcid').
            distinct.select(:author_orcid).
            count

          percent_submissions_per_author = (submitters_as_coauthors * 100) / submitters_orcid.to_f

          csv << ['Submitting authors who coauthored in the past', submitters_orcid, nil, submitters_as_coauthors, nil, percent_submissions_per_author.round(2)]

          # 3. Coauthors who submitted in the past

          csv << ['Coauthors who submitted in the past', submitters_orcid, nil, submitters_as_coauthors, nil, percent_submissions_per_author.round(2)]

          # 4. Coauthors who coauthored in the past

          coauthors = StashEngine::Author.unscoped.joins(resource: [:user, :identifier]).where('orcid != author_orcid').distinct.select(:author_orcid, :identifier).group(:author_orcid, :identifier).count
          multiple_times_coauthors = coauthors.keys.map(&:first).tally.select { |_k, val| val > 1 }.count
          percent_multiple_times_coauthors = (multiple_times_coauthors * 100) / coauthors.count.to_f

          csv << ['Coauthors who coauthored in the past', nil, nil, coauthors.count, multiple_times_coauthors, percent_multiple_times_coauthors.round(2)]

          csv << ['Average number of submissions per author (submitting author)', nil, nil, nil, nil, nil, avg_submissions_per_submitter.round(2)]
          csv << ['Average number of submissions per author (resubmitting author)', nil, nil, nil, nil, nil, avg_submissions_per_resubmitter.round(2)]
        end
      end

      # rubocop:enable Metrics/MethodLength
    end
  end
end
