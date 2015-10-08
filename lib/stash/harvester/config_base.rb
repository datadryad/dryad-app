module Stash
  module Harvester
    class ConfigBase

      def self.config_class_name(namespace)
        names = name.split('::')
        base_name = names.pop
        (names + [namespace, "#{namespace}#{base_name}"]).join("::")
      end

      def self.from_hash(hash)
        config_key = self::CONFIG_KEY
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
