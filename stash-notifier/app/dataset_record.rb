require 'active_support/core_ext/object/to_query'
require_relative './config'
require 'oai'
require 'nokogiri'

class DatasetRecord

  attr_reader :timestamp, :merritt_id, :doi, :version, :title, :raw_xml

  # the static method to get records of this DatasetRecord class, this follows an activerecord like pattern
  def self.find(start_time:, end_time:, set: nil)
    start_time = start_time.utc.iso8601
    end_time = end_time.utc.iso8601

    # retrieve oai records
    opts = { 'metadata_prefix': 'stash_wrapper', from: start_time, until: end_time, set: set }.compact
    oai_record_response = self.get_oai_response(opts)
    return [] unless oai_record_response.class == OAI::ListRecordsResponse

    # convert to datset record objects for things we care about
    self.make_ds_record_array(oai_record_response)
  end

  def self.get_oai_response(opts)
    # get the set
    client = ::OAI::Client.new(Config.oai_base_url)
    begin
      url = "#{Config.oai_base_url}?#{opts.to_query}"
      Config.logger.info("Checking OAI feed for #{opts[:set]} -- #{url}")
      client.list_records(opts)
    rescue OAI::Exception => ex
      Config.logger.info("No new records were found from OAI query: #{url}")
      return nil
    rescue Faraday::ConnectionFailed
      Config.logger.warn("Unable to connect to #{url}")
      return nil
    end
  end

  def self.make_ds_record_array(oai_response)
    oai_response.map {|oai_record| DatasetRecord.new(oai_record) }
  end

  def initialize(oai_record)
    @raw_xml = oai_record.metadata.to_s
    nokogiri_doc = Nokogiri(@raw_xml)
    nokogiri_doc.remove_namespaces!
    @deleted = oai_record.deleted? || false
    @timestamp = Time.parse(oai_record.header.datestamp)
    @merritt_id = oai_record.header.identifier
    @doi = nokogiri_doc.xpath("/metadata/stash_wrapper/identifier[@type='DOI'][1]").text.strip
    @version = nokogiri_doc.xpath("/metadata/stash_wrapper/stash_administrative/version/version_number[1]").text.strip
    @title = nokogiri_doc.xpath("/metadata/stash_wrapper/stash_descriptive/resource/titles/title[1]").text.strip
  end

  def deleted?
    @deleted
  end

end