require 'logger'

module Stash
  Dir.glob(File.expand_path('stash/*.rb', __dir__)).sort.each(&method(:require))

  def self.in_test?
    'test'.casecmp(ENV['STASH_ENV'].to_s).zero?
  end
  private_class_method :in_test?

  # TODO: Make this configurable
  LOG_LEVEL = in_test? ? Logger::DEBUG : Logger::INFO
end
