# :nocov:
require 'byebug'
namespace :authors do

  # example: RAILS_ENV=<environment> bundle exec rake authors:populate_orcid
  desc 'Populate missing ORCIDs for authors'
  task populate_orcid: :environment do
    AuthorsService.new.fix_missing_orcid
  end
end
# :nocov:
