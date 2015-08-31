module Stash
  module Harvester
    class Config

      attr_reader :db_config
      attr_reader :source_config
      attr_reader :index_config

      def initialize(db_config:, source_config:, index_config:)
        @db_config = db_config
        @source_config = source_config
        @index_config = index_config
      end

      def self.from_yaml(yml)
        config = keys_to_syms(YAML.load(yml))
        db_config = config[:db]
        source_config = SourceConfig.from_hash(config[:source])
        index_config = IndexConfig.from_hash(config[:index])
        Config.new(db_config: db_config, source_config: source_config, index_config: index_config)
      end

      private

      def self.keys_to_syms(v)
        return v unless v.respond_to?(:to_h)
        v.to_h.map { |k2, v2| [k2.to_sym, keys_to_syms(v2)] }.to_h
      end
    end
  end
end
