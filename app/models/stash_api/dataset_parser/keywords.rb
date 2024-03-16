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

        @hash['keywords'].each do |kw|
          next if kw.blank?

          @resource.subjects << StashDatacite::Subject.find_or_create_subject(kw, exact: true)
        end
      end

      private

      def clear
        @resource.subjects.delete(@resource.subjects.non_fos)
      end
    end
  end
end
