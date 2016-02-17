ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# ########################################
# Set default port to 3001

require 'rails/commands/server'

module ServerExtensions
  def default_options
    super.merge!(Port: 3001)
  end
end

module Rails
  class Server
    prepend ServerExtensions
  end
end
