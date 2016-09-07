require 'kaminari'
module StashEngine
  class Engine < ::Rails::Engine
    isolate_namespace StashEngine

    # Initializer to combine this engines static assets with the static assets of the hosting site.
    initializer 'static assets' do |app|
      app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
    end
  end
  # see http://stackoverflow.com/questions/20734766/rails-mountable-engine-how-should-apps-set-configuration-variables

  class << self
    mattr_accessor :app, :tenants
  end

  # this function maps the vars from your app into your engine
  def self.setup
    yield self
  end
end
