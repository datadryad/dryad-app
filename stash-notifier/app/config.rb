require 'byebug'
require 'yaml'
require 'ostruct'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/attribute_accessors'
require 'logger'

# rubocop:disable Style/ClassVars
# this is a mostly(?) read-only module to supply the simple config to everywhere that needs it and some common methods
module Config

  cattr_reader :logger, :environment, :update_base_url, :oai_base_url, :sets

  # rubocop:disable Metrics/MethodLength
  def self.initialize(environment: 'development', logger_std_out: false)
    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    path = File.join(proj_root, 'config', 'notifier.yml')
    @@settings = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(path)[environment])
    @@environment = environment

    @@logger = if logger_std_out
                 Logger.new(STDOUT)
               else
                 Logger.new(File.join(proj_root, 'log', "#{environment}.log"))
               end

    @@update_base_url = @@settings[:update_base_url]
    @@oai_base_url = @@settings[:oai_base_url]
    @@sets = @@settings[:sets]
  end
  # rubocop:enable Metrics/MethodLength

end
# rubocop:enable Style/ClassVars
