module StashApi
  class DatasetParser
    class Keywords

      def initialize(resource:, hash:)
        @resource = resource
        @hash = hash
      end

      # keywords looks like this
      # "keywords": [
      #    "Abnormal bleeding",
      #    "Cat",
      #    "Host",
      #    "Computer",
      #    "Log"
      # ]

      def parse
        clear
        return if @hash['keywords'].blank?
        @hash['keywords'].each do |kw|
          next if kw.blank?
          @resource.subjects << find_or_create_subject(keyword: kw)
        end
      end

      private

      def clear
        @resource.subjects.clear
      end

      def find_or_create_subject(keyword:)
        subs = StashDatacite::Subject.where(subject: keyword)
        return subs.first unless subs.blank?
        StashDatacite::Subject.create(subject: keyword)
      end
    end
  end
end
