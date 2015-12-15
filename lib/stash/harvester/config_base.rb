module Stash
  module Harvester

    class ConfigBase

      # TODO: document this in a way that's not insane
      def self.config_class_name(namespace)
        namespace = Util.ensure_camel_case(namespace)
        names = name.split('::')
        base_name = names.pop
        (names + [namespace, "#{namespace}#{base_name}"]).join('::')
      end

      def self.config_key
        fail NoMethodError, "#{name} should implement config_key to return a domain-appropriate configuration key"
      end

      def self.from_hash(hash)
        if hash
          namespace = hash[config_key]
          config_class = for_namespace(namespace)
          begin
            config_params = hash.clone
            config_params.delete(config_key)
            config_class.new(config_params)
          rescue => e
            raise ArgumentError, "Can't construct configuration class #{config_class} for config #{namespace}: #{e.message}"
          end
        else
          Stash::Harvester.log.error("No configuration found for config section '#{config_key}'")
          nil
        end
      end

      def self.from_yaml(yml)
        yaml = YAML.load(yml)
        hash = Util.keys_to_syms(yaml)
        from_hash(hash)
      end

      def self.for_namespace(namespace)
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
