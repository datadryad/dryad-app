# :nocov:
require 'byebug'
require 'csv'

module Tasks
  module Reports
    class AuthorReports
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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

          res = ActiveRecord::Base.connection.execute <<~SQL
            select  count(distinct(users.orcid))
            from stash_engine_users as users
            inner join stash_engine_resources as user_res on user_res.user_id = users.id AND user_res.deleted_at IS NULL
            INNER JOIN stash_engine_identifiers ON user_res.id = stash_engine_identifiers.latest_resource_id AND stash_engine_identifiers.deleted_at IS NULL
            inner join stash_engine_authors as user_author on user_author.author_orcid = users.orcid and user_res.id != user_author.resource_id
            inner join stash_engine_resources as author_res on user_author.resource_id=author_res.id AND author_res.deleted_at IS NULL
            where user_res.created_at > author_res.created_at
          SQL
          submitters_as_coauthors = res.first[0]
          submitters_orcid = StashEngine::Resource.latest_per_dataset.joins(:user).distinct.select(:orcid).count

          percent_submissions_per_author = (submitters_as_coauthors * 100) / submitters_orcid.to_f

          csv << ['Submitting authors who coauthored in the past', submitters_orcid, nil, submitters_as_coauthors, nil,
                  percent_submissions_per_author.round(2)]

          # 3. Coauthors who submitted in the past
          # Same as above with different date condition direction

          res = ActiveRecord::Base.connection.execute <<~SQL
            select  count(distinct(users.orcid))
            from stash_engine_users as users
            inner join stash_engine_resources as user_res on user_res.user_id = users.id AND user_res.deleted_at IS NULL
            INNER JOIN stash_engine_identifiers ON user_res.id = stash_engine_identifiers.latest_resource_id AND stash_engine_identifiers.deleted_at IS NULL
            inner join stash_engine_authors as user_author on user_author.author_orcid = users.orcid and user_res.id != user_author.resource_id
            inner join stash_engine_resources as author_res on user_author.resource_id=author_res.id AND author_res.deleted_at IS NULL
            where user_res.created_at < author_res.created_at
          SQL
          submitters_as_coauthors = res.first[0]
          submitters_orcid = StashEngine::Resource.latest_per_dataset.joins(:user).distinct.select(:orcid).count

          percent_submissions_per_author = (submitters_as_coauthors * 100) / submitters_orcid.to_f

          csv << ['Coauthors who submitted in the past', submitters_orcid, nil, submitters_as_coauthors, nil, percent_submissions_per_author.round(2)]

          # 4. Coauthors who coauthored in the past

          coauthors = StashEngine::Author.unscoped.joins(resource: %i[user identifier])
            .where('orcid != author_orcid')
            .distinct.select(:author_orcid, :identifier)
            .group(
              :author_orcid, :identifier
            ).count
          multiple_times_coauthors = coauthors.keys.map(&:first).tally.select { |_k, val| val > 1 }.count
          percent_multiple_times_coauthors = (multiple_times_coauthors * 100) / coauthors.count.to_f

          csv << ['Coauthors who coauthored in the past', nil, nil, coauthors.count, multiple_times_coauthors,
                  percent_multiple_times_coauthors.round(2)]

          csv << ['Average number of submissions per author (submitting author)', nil, nil, nil, nil, nil, avg_submissions_per_submitter.round(2)]
          csv << ['Average number of submissions per author (resubmitting author)', nil, nil, nil, nil, nil, avg_submissions_per_resubmitter.round(2)]
        end
      end

      def self.random_submitters
        submitters = StashEngine::Resource.latest_per_dataset
          .select(:user_id).distinct
          .where(stash_engine_resources: { created_at: 2.year.ago..Time.now })
          .sample(250)

        CSV.open(File.join(Rails.root.join('tmp'), "Random_Submitters_Report-#{Time.now.strftime('%Y-%m-%d')}.csv"), 'wb') do |csv|
          csv << ['First Name', 'Last Name', 'Email', 'Orcid ID', 'Tenant ID', 'Number of Submissions', 'First Submission Date',
                  'Last Submission Date']
          submitters.each do |submitter|
            user = StashEngine::User.find(submitter.user_id)
            submission_dates = StashEngine::Resource.where(user_id: user.id)
              .select('MAX(created_at) as last_submission_date, MIN(created_at) as first_submission_date')
              .first
            csv << [user.first_name, user.last_name, user.email, user.orcid, user.tenant_id,
                    StashEngine::Resource.latest_per_dataset.where(user_id: user.id).count,
                    submission_dates.first_submission_date, submission_dates.last_submission_date]
          end
        end
        true
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
# :nocov:
