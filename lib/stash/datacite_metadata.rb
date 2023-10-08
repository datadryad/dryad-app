require 'rest-client'
require 'json'
require 'cgi'

# this is really for DataCite event metadata for citations
module Stash
  class DataciteMetadata

    attr_reader :doi

    DATACITE_BASE = 'http://doi.org/'.freeze
    DATACITE_RESOLVER_BASE = 'https://doi.org/'.freeze

    def initialize(doi:)
      @doi = doi
      @doi = doi[4..] if doi.downcase.start_with?('doi:')
      match_data = %r{^https?://doi.org/(\S+/\S+)$}.match(@doi)
      @doi = match_data[1] if match_data
      @metadata = nil
    end

    # lookup raw datacite metadata and cache (including failures to get any, that false business)
    def raw_metadata
      return @metadata unless @metadata.nil?
      return nil if @metadata == false

      response = RestClient.get "#{DATACITE_BASE}#{CGI.escape(@doi)}", accept: 'application/citeproc+json'
      @metadata = JSON.parse(response.body)
    rescue RestClient::Exception, Errno::ECONNREFUSED, JSON::ParserError => e
      logger.error("#{Time.new.utc} Could not get response from DataCite for metadata lookup #{@doi}")
      logger.error("#{Time.new.utc} #{e}")
      @metadata = false
      nil
    end

    def author_names
      names = raw_metadata['author']
      return '' if names.blank?

      names = names.map { |i| name_finder(i) }
      return "#{names.first} et al." if names.length > 4

      names.join('; ')
    end

    def year_published
      dp = raw_metadata.dig('issued', 'date-parts')
      return dp.first.first unless dp.blank?

      ''
    end

    def title
      raw_metadata['title']
    end

    def publisher
      raw_metadata['publisher']
    end

    def journal
      raw_metadata['container-title']
    end

    def resource_type
      return raw_metadata['type'].capitalize if raw_metadata['type']

      ''
    end

    def doi_link
      "#{DATACITE_RESOLVER_BASE}#{@doi.downcase}"
      # raw_metadata['id']
    end

    # finds the name from the names hash, might be item['literal'] or item['given'] and item['family']
    def name_finder(item)
      return "#{item['family']}, #{item['given']}" if item['family'] || item['given']

      item['literal']
    end

    def html_citation
      return nil if raw_metadata.nil?

      # html_safe when concatenated with other stuff makes non-html-safe escaped
      ''.html_safe + "#{author_names} (#{year_published}), #{title}, #{journal}, #{resource_type}, " +
          "<a href=\"#{doi_link}\" target=\"_blank\">#{doi_link}</a>".html_safe
    end

    def logger
      Rails.logger
    end

    # def self.test_data
    #   dois = %w[10.3352/jeehp.2013.10.3 10.5060/D8H59D 10.7280/D1NP4M 10.7932/BDSN 10.13016/M2WK6V
    #             10.3886/ICPSR36151.v5 10.2390/biecoll-jib-2009-108 10.1159/000489098 10.14288/1.0303795 10.7916/d8pp0jkc
    #             10.5517/ccdc.csd.cc1k1h8c 10.6068/dp15e7605c65e31 10.15156/bio/sh332819.07fu 10.5281/zenodo.809529
    #             10.17876/plate/dr.2/plates/103_17536 10.13145/bacdive128484.20171208.2.1 10.5169/seals-365408
    #             10.1594/pangaea.676801
    #             10.1093/jme/tjy088 10.1093/ee/nvy084 10.1111/tbed.12916 10.1038/d41586-018-04938-z 10.1207/s15328023top1703_12
    #             10.1016/j.cedpsych.2008.04.002 10.1119/1.4935763 10.1071/Zo08044 10.1371/journal.pone.0057745
    #             10.2305/IUCN.UK.2008.RLTS.T40540A10331066.en 10.1126/science.1200674 10.1111/j.1365-294X.2007.03399.x
    #             10.1016/j.biocon.2007.11.007 10.1038/s41586-018-0036-z 10.1103/PhysRevLett.119.080503
    #             10.1632/pmla.2016.131.2.430 10.1108/eb014124 10.1119/1.1848514 10.1137/1.9781611971132 10.1038/nphys4343]
    #   dois.each do |doi|
    #     dm = Stash::DataciteMetadata.new(doi: doi)
    #     if dm.raw_metadata.nil?
    #       puts "\r\n#{doi} could not be found"
    #     else
    #       puts "\r\n#{doi}"
    #       # pp(dm.raw_metadata)
    #       # byebug
    #       puts dm.html_citation
    #    end
    #    sleep 1
    #    end
    # end

    # getting citation information (where m is the metadata returned)
    # Authors: these are full names not separated last, first
    #     m['data']['attributes']['author'].map{|i| i['literal'] }
    #
    # Year: as string.  Not sure if this is set for all records?
    #     m['data']['attributes']['published']
    #
    # Title:
    #     m['data']['attributes']['title']
    #
    # Publisher: I don't see one exactly.  Perhaps?
    #     "container-title"=>"Figshare"
    #     "member-id"=>"figshare"
    #

    # the resource types are confusing.  Maybe one of these.
    # m['data']['relationships']['resource-type']['data']['id']
    # => "collection"
    #
    # m['data']['attributes']['resource-type-id']
    # => "collection"
    #
    # m['data']['attributes']['resource-type-subtype']
    # => "Collection"

    # link to it
    # m['data']['id'] or maybe m['data']['attributes']['identifier']

  end
end
