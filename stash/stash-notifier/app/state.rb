require 'ostruct'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/attribute_accessors'
require 'json'
require 'time'
require_relative './collection_set'

# rubocop:disable Style/ClassVars
module State

  @@sets = nil

  # ensure the statefile is up to date, with a file and default entries for every set
  def self.ensure_statefile
    default_state = { last_retrieved: Time.at(0).utc.iso8601, retry_status_update: [] }
    my_state = {}
    my_state = load_state_as_hash if File.exist?(statefile_path)
    Config.sets.each do |set|
      my_state[set] = default_state if my_state[set].nil?
    end
    save_state_hash(hash: my_state)
  end

  def self.statefile_path
    # now changed to refer to the config directory under rails which is up quite a few directories
    # File.expand_path(File.join(File.dirname(__FILE__), '..', 'state', "#{Config.environment}.json"))

    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'notifier_state.json'))
  end

  def self.save_state_hash(hash:)
    File.write(statefile_path, JSON.pretty_generate(hash))
  end

  def self.load_state_as_hash
    JSON.parse(File.read(statefile_path)).with_indifferent_access
  end

  def self.sets
    return @@sets unless @@sets.nil?

    @@sets = []
    load_state_as_hash.each do |k, v|
      @@sets.push(CollectionSet.new(name: k, settings: v))
    end
    @@sets
  end

  def self.sets_serialized_to_hash
    output_hash = {}
    sets.each do |item|
      output_hash[item.name] = item.hash_serialized
    end
    output_hash
  end

  # goes through the sets and saves their state since they may have changed
  def self.save_sets_state
    my_hash = sets_serialized_to_hash
    save_state_hash(hash: my_hash)
  end

  # ensures a PID file on running
  def self.create_pid
    @@pid_file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'state', "#{Config.environment}.pid"))
    if File.file?(@@pid_file)
      Config.logger.error("Couldn't run notifier -- already in progress or state/<environment>.pid file not removed")
      abort("Exiting: pid file already exists #{@@pid_file}")
    end
    File.write(@@pid_file, Process.pid)
  end

  def self.remove_pid
    File.delete(@@pid_file)
  end

end
# rubocop:enable Style/ClassVars
