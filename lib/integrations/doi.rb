# an integration for getting citeproc citation JSON for a DOI, offered by both Crossref and DataCite via doi.org

module Integrations
  class Doi < Integrations::Base

    # lookup raw citeproc json for cache
    def citeproc_json(doi)
      @doi = doi.downcase.start_with?('doi:') ? doi[4..] : doi
      match_data = %r{^https?://doi.org/(\S+/\S+)$}.match(@doi)
      @doi = match_data[1] if match_data
      @metadata = nil

      return @metadata unless @metadata.nil?
      return nil if @metadata == false

      @metadata = get_json("https://doi.org/#{CGI.escape(@doi)}", nil, { Accept: 'application/citeproc+json' })
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, JSON::ParserError => e
      Rails.logger.error("#{Time.new.utc} Could not get response from DataCite for metadata lookup #{@doi}")
      Rails.logger.error("#{Time.new.utc} #{e}")
      @metadata = false
      nil
    end

  end
end
