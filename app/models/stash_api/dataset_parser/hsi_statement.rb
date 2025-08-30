module StashApi
  class DatasetParser
    class HsiStatement < StashApi::DatasetParser::BaseParser
      # "hsiStatement": 'All HSI and PPI has been removed from this dataset'

      def parse
        clear
        @resource.descriptions << StashDatacite::Description.create(description: @hash['hsiStatement'].presence, description_type: 'hsi_statement')
      end

      private

      def clear
        @resource.descriptions.where(description_type: 'hsi_statement').destroy_all
      end

    end
  end
end
