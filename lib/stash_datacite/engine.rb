module StashDatacite
  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite
      mattr_accessor :resource_class
      def self.resource_class
        @@resource_class.constantize
      end
  end
end
