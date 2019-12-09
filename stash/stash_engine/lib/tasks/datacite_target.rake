# require_relative 'datacite_target/somefile'

# rubocop:disable Metrics/BlockLength
namespace :counter do

  desc 'test task'
  task test_task: :environment do
    puts 'a test task running in the rails environment'
  end

end