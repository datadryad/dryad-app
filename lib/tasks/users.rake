# :nocov:
require 'byebug'
namespace :users do
  # example: RAILS_ENV=<environment> bundle exec rake users:merge_users -- --old_id 12345 --new_id 4321
  desc 'Merge old and new users (into old account like it works in the UI)'
  task merge_users: :environment do
    args = Tasks::ArgsParser.parse(:old_id, :new_id)
    if ENV['RAILS_ENV'].blank? || args.old_id.blank? || args.new_id.blank?
      puts "Merges two users together, the old user (old datasets) has new user/datasets merged into it and new ORCID copied to it\n\n"
      puts 'Run this script with the line:'
      puts "  RAILS_ENV=<environment> bundle exec rake users:merge_users -- --old_id <old-user-id> --new_id <new-user-id>\n\n"
      puts 'Example: RAILS_ENV=development bundle exec rake users:merge_users -- --old_id 12345 --new_id 4321'
      puts "\nThe user ids should be obtained by looking at id field in the stash_engine_users"
      exit
    end

    old_user = StashEngine::User.find(args.old_id.to_i)
    new_user = StashEngine::User.find(args.new_id.to_i)
    puts 'old user'
    puts '--------'
    pp(old_user)

    puts "\nnew user"
    puts '--------'
    pp(new_user)

    puts "Are you sure you want to combine the two above users?  (Type 'yes' to proceed)"
    response = $stdin.gets
    exit unless response.strip.casecmp('YES').zero?

    # this is what the UI does when they merge accounts
    old_user.merge_user!(other_user: new_user)

    exit
  end

end
# :nocov:
