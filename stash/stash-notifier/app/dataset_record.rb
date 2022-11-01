require 'active_support/core_ext/object/to_query'
require_relative './config'
require 'nokogiri'

class DatasetRecord

  attr_reader :timestamp, :merritt_id, :doi, :version, :title, :raw_xml

  # the static method to get records of this DatasetRecord class, this follows an activerecord like pattern
  def self.find(start_time:, end_time:, set: nil)
    start_time = start_time.utc.iso8601
    end_time = end_time.utc.iso8601

    # retrieve oai records
    opts = { metadata_prefix: 'stash_wrapper', from: start_time, until: end_time, set: set }.compact
    oai_record_response = get_oai_response(opts)
    return [] unless oai_record_response.instance_of?(OAI::ListRecordsResponse)

    # convert to datset record objects for things we care about
    make_ds_record_array(oai_record_response)
  end

  def self.get_oai_response(opts)
    # get the set
    client = ::OAI::Client.new(Config.oai_base_url)
    begin
      url = oai_debugging_url(base_url: Config.oai_base_url, opts: opts)
      # url = "#{Config.oai_base_url}?#{opts.to_query}"
      Config.logger.info("Checking OAI feed for #{opts[:set]} -- #{url}")
      client.list_records(opts)
    rescue OAI::Exception
      Config.logger.info("No new records were found from OAI query: #{url}")
      nil
    rescue Faraday::ConnectionFailed
      Config.logger.error("Unable to connect to #{url}")
      nil
    end
  end

  def self.make_ds_record_array(oai_response)
    oai_response.map { |oai_record| DatasetRecord.new(oai_record) }
  end

  def initialize(oai_record)
    @raw_xml = oai_record.metadata.to_s
    nokogiri_doc = Nokogiri(@raw_xml)
    nokogiri_doc.remove_namespaces!
    @deleted = oai_record.deleted? || false
    @timestamp = Time.parse(oai_record.header.datestamp)
    @merritt_id = oai_record.header.identifier
    @doi = nokogiri_doc.xpath("/metadata/stash_wrapper/identifier[@type='DOI'][1]").text.strip
    # this version is the stash version number, not the merritt one.
    @version = nokogiri_doc.xpath('/metadata/stash_wrapper/stash_administrative/version/version_number[1]').text.strip
    @title = nokogiri_doc.xpath('/metadata/stash_wrapper/stash_descriptive/resource/titles/title[1]').text.strip
  end

  def deleted?
    @deleted
  end

  def self.oai_debugging_url(base_url:, opts:)
    # # http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?verb=ListRecords&from=2018-11-01T18%3A19%3A17Z&metadataPrefix=stash_wrapper&set=cdl_dryaddev&until=2019-01-24T18%3A44%3A29Z
    my_opts = opts.clone
    my_opts[:verb] = 'ListRecords'
    my_opts['metadataPrefix'] = my_opts[:metadata_prefix]
    my_opts.delete(:metadata_prefix)
    "#{base_url}?#{my_opts.to_query}"
  end

end
