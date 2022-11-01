# require "active_support/core_ext/hash/indifferent_access"
require 'active_support/core_ext/hash'
require_relative 'config'
require_relative 'dataset_record'
require_relative 'dryad_notifier'
require 'time'

class CollectionSet

  attr_reader :name
  attr_accessor :last_retrieved

  # The settings hash that is passed in looks like this
  # { last_retrieved: '2019-01-23T00:41:43Z',
  #   retry_status_update:
  #     [ { doi: '1245/6332', merritt_id: 'http://n2t.net/klj/2344', version: '1', time: '2019-01-21T04:43:19Z'},
  #       { doi: '348574/38483', merritt_id: 'http://n2t.net/klksj/843', version: '2', time: '2019-01-07T23:59:39Z'} ]
  # }

  def initialize(name:, settings:)
    @name = name
    @last_retrieved = Time.iso8601(settings[:last_retrieved]).utc
    r = settings[:retry_status_update]

    # changes array of hashes (see above) into key = :doi and value is hash of the rest of hash
    @retry_hash = Hash[*r.map { |i| [i[:doi], i.except(:doi)] }.flatten]
    @retry_hash.each_value { |v| v[:time] = Time.iso8601(v[:time]).utc } # convert times from iso8601 strings to ruby times
  end

  # main loop for retrying errors
  def retry_errored_dryad_notifications
    # get errored notifications and try them again
    retry_list.each do |item|
      Config.logger.info("Retrying notification of dryad for doi:#{item[:doi]}, version: #{item[:version]}, merritt_id: #{item[:merritt_id]}")
      dn = DryadNotifier.new(doi: item[:doi], merritt_id: item[:merritt_id], version: item[:version])
      remove_retry_item(doi: item[:doi]) if dn.notify == true
    end
  end

  # main loop for notifying from OAI-PMH feed
  def notify_dryad
    records = DatasetRecord.find(start_time: last_retrieved, end_time: Time.new.utc, set: name)
    new_last_retrieved = last_retrieved # default to old value for no records in set
    records.each do |record|
      next if record.deleted?

      Config.logger.info("Notifying Dryad status, doi:#{record.doi}, version: #{record.version} ---- #{record.title} (#{record.timestamp.iso8601})")
      new_last_retrieved = record.timestamp

      # send status updates to Dryad for merritt state and add any failed items to the retry list
      dn = DryadNotifier.new(doi: record.doi, merritt_id: record.merritt_id, version: record.version)
      add_retry_item(doi: record.doi, merritt_id: record.merritt_id, version: record.version) unless dn.notify
    end
    self.last_retrieved = new_last_retrieved
  end

  def dois_to_retry
    @retry_hash.keys
  end

  # add a retry item to the list
  def add_retry_item(doi:, merritt_id:, version:)
    @retry_hash[doi] = { merritt_id: merritt_id, version: version, time: Time.new.utc }
  end

  # remove a retry item from the list
  def remove_retry_item(doi:)
    @retry_hash.delete(doi)
  end

  # cleans any retry items older than n days
  def clean_retry_items!(days:)
    time_ago_cutoff = (Time.new - (24 * 60 * 60 * days)).utc
    @retry_hash.delete_if { |_, v| v[:time] < time_ago_cutoff }
  end

  def hash_serialized
    { last_retrieved: last_retrieved.utc.iso8601,
      retry_status_update: retry_list }
  end

  # gives a list of items like {doi: '2072/387....', merritt_id: 'http://n2t.net/jsk...', version: "1", time: '2019-02-21....'}
  def retry_list
    arr = []
    @retry_hash.each do |k, v|
      arr.push(doi: k, merritt_id: v[:merritt_id], version: v[:version], time: v[:time].utc.iso8601)
    end
    arr
  end

end
