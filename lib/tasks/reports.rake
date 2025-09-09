# :nocov:
require_relative 'reports/ror_author_datasets'
require_relative 'reports/institution_datasets'
namespace :reports do

  # example: RAILS_ENV=production bundle exec rake reports:ror_author_submitted -- --tenant ucop
  # Not using Rake standard way to do arguments because it's ridiculous
  desc 'Shows information about datasets and authors for an institution via ror IDs defined in the tenant'
  task ror_author_submitted: :environment do
    args = Tasks::ArgsParser.parse(:tenant)

    unless ENV['RAILS_ENV'] && args.tenant
      puts 'RAILS_ENV and tenant bash variables must be explicitly set before running this script'
      puts 'example: RAILS_ENV=production bundle exec rake reports:ror_author_submitted -- --tenant ucop'
      next
    end
    Tasks::Reports::RorAuthorDatasets.submitted_report(tenant: args.tenant.strip)
    exit
  end

  # example: RAILS_ENV=production bundle exec rails reports:from_text_institution -- --name "Max Planck"
  # gets all from an institution by author or contributor (funder)
  task from_text_institution: :environment do
    args = Tasks::ArgsParser.parse(:name)
    pp args.name
    unless ENV['RAILS_ENV'] && args.name
      puts 'RAILS_ENV and name bash variables must be explicitly set before running this script'
      puts 'example: RAILS_ENV=production bundle exec rails reports:from_text_institution -- --name "Max Planck"'
      next
    end
    puts "Creating dataset report for items with author or contributor affiliation like \"#{args.name}\""
    Tasks::Reports::InstitutionDatasets.datasets_by_name(name: args.name)
    puts "Done, see #{args.name}-#{Time.now.strftime('%Y-%m-%d')}.tsv"
    exit
  end

  desc 'Generates a PDF report with monthly stats for GREI'
  task grei_monthly_report: :environment do
    Tasks::Reports::GREI.generate_monthly_report
  end
end
# :nocov:
