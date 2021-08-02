require_relative 'dev_ops/passenger'
require_relative 'dev_ops/download_uri'

# rubocop:disable Metrics/BlockLength
namespace :notifier do

  desc 'run the notifier'
  task :execute do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
  end
end