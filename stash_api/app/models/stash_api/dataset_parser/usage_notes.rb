module StashApi
  class DatasetParser
    class UsageNotes

      def initialize(resource:, hash:)
        @resource = resource
        @hash = hash
      end

      # methods looks like this
      # "usageNotes": 'Use carefully and parse results underwater.'

      def parse
        clear
        return if @hash['usageNotes'].nil?
        @resource.descriptions << StashDatacite::Description.create(description: @hash['usageNotes'],
                                                                    description_type: 'other')
      end

      private

      def clear
        @resource.descriptions.where(description_type: 'other').destroy_all
      end

    end
  end
end