require_relative '../../script/clear_data'
namespace :app_data do
  desc 'Clear data from database (stash and datacite) and solr for environment'
  task clear: :environment do
    puts "Are you sure you want to clear the data in the environment #{Rails.env}?  (Type 'yes' to proceed.)"
    response = STDIN.gets
    ClearData.clear if response.strip.casecmp('YES').zero? && Rails.env != 'production'
  end
end
