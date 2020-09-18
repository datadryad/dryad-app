require_relative 'reports/ror_author_datasets'
namespace :reports do

  # use like: bundle exec rake reports:ror_author_submitted tenant=ucop RAILS_ENV=production
  # Not using Rake standard way to do arguments because it's ridiculous
  desc 'Shows information about datasets and authors for an institution via ror IDs defined in the tenant'
  task ror_author_submitted: :environment do
    unless ENV['RAILS_ENV'] && ENV['tenant']
      puts 'RAILS_ENV and tenant bash variables must be explicitly set before running this script'
      puts 'example: bundle exec rake reports:ror_author_submitted tenant=ucop RAILS_ENV=production'
      next
    end
    RorAuthorDatasets.submitted_report(tenant: ENV['tenant'].strip)
  end
end
