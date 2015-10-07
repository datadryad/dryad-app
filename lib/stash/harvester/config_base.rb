module Stash
  module Harvester
    class ConfigBase

      def self.config_key
        fail NoMethodError "#{self.class} should override #config_key to return a config key, but it doesn't"
      end

      def self.config_class_name(_namespace)
        fail NoMethodError "#{self.class} should override #config_class_name to generate a class name, but it doesn't"
      end

      def self.from_hash(hash)
        namespace = hash[config_key]
        config_class = for_namespace(namespace)
        begin
          config_params = hash.clone
          config_params.delete(config_key)
          config_class.new(config_params)
        rescue => e
          raise ArgumentError, "Can't construct configuration class #{config_class} for config #{namespace}: #{e.message}"
        end
      end

      def self.for_namespace(namespace)
        namespace = Util.ensure_leading_cap(namespace)
        class_name = config_class_name(namespace)
        begin
          Kernel.const_get(class_name)
        rescue => e
          raise ArgumentError, "Can't find configuration class '#{class_name}' for namespace '#{namespace}': #{e.message}"
        end
      end

    end
  end
end
