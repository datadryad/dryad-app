require_relative 'reports/ror_author_datasets'
require_relative 'reports/institution_datasets'
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

  # gets all from an institution by author or contributor (funder)
  task from_text_institution: :environment do
    unless ENV['RAILS_ENV'] && ENV['name']
      puts 'RAILS_ENV and name bash variables must be explicitly set before running this script'
      puts 'example: bundle exec rails reports:from_text_institution name="Max Planck" RAILS_ENV=production'
      next
    end
    puts "Creating dataset report for items with author or contributor affiliation like \"#{ENV.fetch('name', nil)}\""
    InstitutionDatasets.datasets_by_name(name: ENV.fetch('name', nil))
    puts "Done, see #{ENV.fetch('name', nil)}-#{Time.now.strftime('%Y-%m-%d')}.tsv"
  end
end
