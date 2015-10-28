module StashEngine
  class Engine < ::Rails::Engine
    isolate_namespace StashEngine
  end

  # see http://stackoverflow.com/questions/20734766/rails-mountable-engine-how-should-apps-set-configuration-variables

  class << self
    mattr_accessor :tenants, :app
    self.tenants = {:key => 'value'} #this would be the default value if not set
  end

  # this function maps the vars from your app into your engine
  def self.setup(&block)
    yield self
  end


end
