module Datacite
  class Metadata

    attr_reader :doi

    def initialize(doi:)
      @doi = doi.downcase.start_with?('doi:') ? doi[4..] : doi
    end

    def result
      Integrations::Datacite.new.query("/dois/#{@doi}")
    end

    def citations
      citations = result.dig('data', 'relationships', 'citations', 'data')
      citations&.map { |c| c['id'] } || []
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      Rails.logger.error("#{Time.new.utc} Could not get citations from DataCite for : #{@doi}")
      Rails.logger.error("#{Time.new.utc} #{e}")
      []
    end
  end
end
