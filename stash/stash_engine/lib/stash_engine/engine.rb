require 'kaminari'
require 'wicked_pdf'
require 'ckeditor'
require_relative('counter_log')

module StashEngine
  class Engine < ::Rails::Engine
    isolate_namespace StashEngine

    # Initializer to combine this engines static assets with the static assets of the hosting site.
    initializer 'static assets' do |app|
      # in production these should be served by the web server? we think? (DM 2016-11-09)
      # see http://stackoverflow.com/questions/30563342/rails-cant-start-when-serve-static-assets-disabled-in-production
      if Rails.application.config.public_file_server.enabled
        app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
      end
    end
  end
  # see http://stackoverflow.com/questions/20734766/rails-mountable-engine-how-should-apps-set-configuration-variables
  class << self
    mattr_accessor :app, :tenants

    def counter_log(*items)
      StashEngine::CounterLog.log(items)
    end
  end

  # this function maps the vars from your app into your engine
  def self.setup
    yield self
  end
end
