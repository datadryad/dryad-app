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

          @resource.subjects << find_or_create_subject(keyword: kw)
        end
      end

      private

      def clear
        @resource.subjects.delete(@resource.subjects.non_fos)
      end

      def find_or_create_subject(keyword:)
        subs = StashDatacite::Subject.where(subject: keyword)
        return subs.first unless subs.blank?

        StashDatacite::Subject.create(subject: keyword)
      end
    end
  end
end
