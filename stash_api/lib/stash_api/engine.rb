# frozen_string_literal: true

module StashApi
  class Engine < ::Rails::Engine
    isolate_namespace StashApi

    config.generators do |g|
      g.test_framework :rspec
    end

    # Initializer to combine this engines static assets with the static assets of the hosting site.
    # this might help with annoying caching
    # https://stackoverflow.com/questions/6962896/how-do-i-prevent-rails-3-1-from-caching-static-assets-to-rails-cache
    initializer 'static assets' do |app|
      app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
    end
  end
end
