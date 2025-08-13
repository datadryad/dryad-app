module StashApi
  class DatasetParser
    class Keywords < StashApi::DatasetParser::BaseParser

      # keywords looks like this
      # "keywords": [
      #    "Abnormal bleeding",
      #    "Cat",
      #    "Host",
      #    "Computer",
      #    "Log"
      # ]

      def parse
        return if @hash['keywords'].blank?

        clear

        Subjects::CreateService.new(@resource, @hash['keywords']).call
      end

      private

      def clear
        @resource.subjects.delete(@resource.subjects.non_fos)
      end
    end
  end
end
