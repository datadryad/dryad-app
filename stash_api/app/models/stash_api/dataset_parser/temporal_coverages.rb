module StashApi
  class DatasetParser
    class TemporalCoverages < StashApi::DatasetParser::BaseParser

      def parse
        clear
        return if @hash['temporalCoverages'].nil?
        @hash['temporalCoverages'].each { |temp| @resource.descriptions << StashDatacite::TemporalCoverage.create(description: temp) }
      end

      def clear
        StashDatacite::TemporalCoverage.where(resource_id: @resource.id).destroy_all
      end

    end
  end
end
