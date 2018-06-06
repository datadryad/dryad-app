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
      @metadata = nil
    end

    def raw_metadata
      return @metadata unless @metadata.nil?
      response = RestClient.get "#{DATACITE_BASE}#{@doi}"
      return @metadata = JSON.parse(response.body)
    rescue RestClient::Exception => ex
      logger.error("#{Time.new} Could not get response from DataCite for metadata lookcup #{@doi}")
      logger.error("#{Time.new} #{ex}")
      return nil
    end

    def author_names
      names = raw_metadata.dig('data', 'attributes', 'author')
      return '' if names.blank?
      names = names.map { |i| i['literal'] }
      return "#{names.first} et al." if names.length > 4
      names.join('; ')
    end

    def logger
      Rails.logger
    end

    # random list of DOIs
    # dois = %w[10.3352/jeehp.2013.10.3 10.7280/D1NP4M 10.1130/2012.MCH101 10.7932/BDSN 10.1016/j.neuron.2018.04.031
    #           10.1016/j.cub.2018.04.033 10.1016/j.ymeth.2015.09.003 10.13016/M2WK6V 10.3886/ICPSR36151.v5
    #           10.1097/00002030-199011000-00007 10.1371/journal.pcbi.0030225 10.1073/pnas.1424184112 10.1101/057307]

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
