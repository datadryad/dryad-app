require 'colorize'
require 'singleton'
require 'solr_wrapper'
require 'uri'

class SolrInstance

  include Singleton

  SOLR_VERSION = '5.2.1'.freeze
  CONF_DIR = 'spec/config/solr/conf'.freeze
  BLACKLIGHT_YML = 'config/blacklight.yml'.freeze
  COLLECTION_NAME = 'geoblacklight'.freeze

  def initialize
    start
  end

  def start
    start_solr
    create_collection
  rescue StandardError => ex
    warn(ex)
    stop
    raise
  end

  def stop
    delete_collection
  ensure
    stop_solr
  end

  private

  def solr_env
    # For macOS local development, run Solr under Java 8 even if Java 9 is the default
    @solr_env ||= begin
      return ENV unless ENV['JAVA_HOME']
      return ENV unless ENV['JAVA_HOME'].include?('jdk-9')
      mac_jdk8_home ||= `[[ -f /usr/libexec/java_home && -x /usr/libexec/java_home ]] && /usr/libexec/java_home -v 1.8`.strip!
      return ENV unless mac_jdk8_home
      ENV.to_h.merge!('JAVA_HOME' => mac_jdk8_home)
    end
  end

  def create_collection
    begin
      @solr_instance.delete(COLLECTION_NAME)
      info "Collection #{COLLECTION_NAME} already exists ... deleted stale collection"
    rescue StandardError
      # We don't care if this fails, its just ensuring that the collection is fresh
      info("Attempting to delete #{COLLECTION_NAME} ... #{COLLECTION_NAME} not found")
    end
    info "Creating collection #{COLLECTION_NAME} from configuration #{CONF_DIR}"
    @collection = @solr_instance.create(dir: CONF_DIR, name: COLLECTION_NAME)
    info 'Collection created'
    @collection
  end

  def delete_collection
    return unless @collection.present?
    info "Deleting collection #{@collection}"
    @solr_instance.delete(@collection)
    @collection = nil
  end

  def start_solr
    info "Starting Solr #{SOLR_VERSION} on port #{port} with JAVA_HOME=#{solr_env['JAVA_HOME']}"
    # WebMock.allow_net_connect!
    @solr_instance = SolrWrapper.instance(verbose: true, port: port, version: SOLR_VERSION, env: solr_env)
    @solr_instance.start
    # WebMock.disable_net_connect!(allow_localhost: true)
    info 'Solr started'
    # rubocop:disable Style/GlobalVars
    $solr_running = true
    # rubocop:enable Style/GlobalVars
  end

  def stop_solr
    info 'Stopping Solr'
    @solr_instance.stop
    # rubocop:disable Style/GlobalVars
    $solr_running = false
    # rubocop:enable Style/GlobalVars
  end

  def port
    config[:port]
  end

  def config
    @config ||= begin
      # apparently have to do the true to enable aliases with safe_load
      # rubocop:disabledd Lint/Debugger: Remove debugger entry point byebug
      # byebug
      # rubocop:enabledd Lint/Debugger: Remove debugger entry point byebug
      blacklight_config = YAML.safe_load(ERB.new(File.read(BLACKLIGHT_YML)).result, [], [], true)['test']
      # blacklight_config = YAML.safe_load(File.read(BLACKLIGHT_YML), [], [], true)['test']
      solr_uri = URI.parse(blacklight_config['url'])
      {
        port: solr_uri.port,
        collection: solr_uri.path.split('/').last
      }
    end
  end

  def info(msg)
    puts msg.to_s.colorize(:blue)
  end

  def warn(msg)
    puts msg.to_s.colorize(:red)
  end

end
