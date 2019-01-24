# require "active_support/core_ext/hash/indifferent_access"
require 'active_support/core_ext/hash'
require_relative './config'
require 'time'

class CollectionSet

  attr_reader :name
  attr_accessor :last_retrieved

  # The settings hash that is passed in looks like this
  # { last_retrieved: '2019-01-23T00:41:43Z',
  #   retry_status_update:
  #     [ { doi: '1245/6332', merritt_id: 'http://n2t.net/klj/2344', time: '2019-01-21T04:43:19Z'},
  #       { doi: '348574/38483', merritt_id: 'http://n2t.net/klksj/843', time: '2019-01-07T23:59:39Z'} ]
  # }

  def initialize(name:, settings:)
    @name = name
    @last_retrieved = Time.iso8601(settings[:last_retrieved])
    r = settings[:retry_status_update]

    # changes array of hashes (see above) into key = :doi and value is hash of the rest of hash
    @retry_hash = Hash[ *r.map{ |i| [ i[:doi], i.except(:doi) ] }.flatten ]
    @retry_hash.each { |_, v| v[:time] = Time.iso8601(v[:time]) } # convert times from iso8601 strings to ruby times
  end

  def dois_to_retry
    @retry_hash.keys
  end

  # add a retry item to the list
  def add_retry_item(doi:, merritt_id:)
    @retry_hash[doi] = { merritt_id: merritt_id, time: Time.new.utc }
  end

  # remove a retry item from the list
  def remove_retry_item(doi:)
    @retry_hash.delete(doi)
  end

  # cleans any retry items older than n days
  def clean_retry_items!(days:)
    time_ago_cutoff = (Time.new - 24 * 60 * 60 * days).utc
    @retry_hash.delete_if { |_, v| v[:time] < time_ago_cutoff }
  end

  def hash_serialized
    { last_retrieved: last_retrieved.utc.iso8601,
      retry_status_update: retry_list
    }
  end

  # gives a list of items like {doi: '2072/387....', merritt_id: 'http://n2t.net/jsk...', time: '2019-02-21....'}
  def retry_list
    arr = []
    @retry_hash.each do |k, v|
      arr.push({ doi: k, merritt_id: v[:merritt_id], time: v[:time].utc.iso8601 } )
    end
    arr
  end

end