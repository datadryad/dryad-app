module Stash
  module Harvester
    class Config
      def initialize(db_config:, source_config:, index_config:)
        @db_config = db_config
        @source_config = source_config
        @index_config = index_config
      end
    end
  end
end
