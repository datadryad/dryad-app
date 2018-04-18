module StashApi
  class DatasetParser
    class Methods

      def initialize(resource:, hash:)
        @resource = resource
        @hash = hash
      end

      # methods looks like this
      # "methods": "<p><br>\r\nMany mathematicians would agree that, had it not been for systems," +
      # " the emulation of active networks might never have occurred. We view algorithms as following a cycle of four" +
      # " phases: simulation, investigation, observation, and investigation. After years of robust research into Boolean" +
      # " logic, we confirm the evaluation of Smalltalk. to what extent can spreadsheets be evaluated to realize this " +
      # "intent?</p>\r\n"

      def parse
        clear
        return if @hash['methods'].nil?
        @resource.descriptions << StashDatacite::Description.create(description: @hash['methods'],
                                                                    description_type: 'methods')
      end

      private

      def clear
        @resource.descriptions.where(description_type: 'methods').destroy_all
      end

    end
  end
end
