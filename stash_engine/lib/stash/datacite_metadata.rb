require 'rest-client'
require 'json'

module Stash
  class DataciteMetadata

    attr_reader :doi

    DATACITE_BASE = 'https://api.datacite.org/works/'.freeze

    def initialize(doi:)
      @doi = doi
      @doi = doi[4..-1] if doi.downcase.start_with?('doi:')
      match_data = %r{^https?://doi.org/(\S+\/\S+)$}.match(@doi)
      @doi = match_data[1] if match_data
    end

    def descriptive_metadata
      response = RestClient.get "#{DATACITE_BASE}#{@doi}"
      return JSON.parse(response.body)
    rescue RestClient::Exception => ex
      logger.error("#{Time.new} Could not get response from DataCite for metadata lookcup #{@doi}")
      logger.error("#{Time.new} #{ex}")
      return nil
    end

    def logger
      Rails.logger
    end

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
