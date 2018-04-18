module StashApi
  class DatasetParser
    class BaseParser

      def initialize(resource:, hash:)
        @resource = resource
        @hash = hash
      end

      def parse
        raise 'Please override the parse method.'
      end

      # also suggested to have a private method called 'clear' to clear out any previous data when parsing new data

    end
  end
end