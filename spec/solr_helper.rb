require 'solr_wrapper'
require 'colorize'
require 'uri'

# TODO: figure out how to move some of this to stash_discovery
module SolrHelper
  class << self

    SOLR_VERSION = '5.2.1'.freeze
    CONF_DIR = 'spec/config/solr/conf'.freeze
    BLACKLIGHT_YML = 'config/blacklight.yml'.freeze
    COLLECTION_NAME = 'geoblacklight'.freeze

    def start
      return if solr_instance
      self.solr_instance = start_new_instance
      self.collection = create_collection
    rescue => ex
      warn(ex)
      stop
      raise
    end

    def stop
      return unless solr_instance
      begin
        info "Deleting collection #{collection}" if collection
        solr_instance.delete(collection) if collection
        self.collection = nil
      ensure
        info 'Stopping Solr'
        solr_instance.stop
        self.solr_instance = nil
      end
    end

    private

    attr_accessor :solr_instance
    attr_accessor :collection

    def create_collection
      info "Creating collection #{COLLECTION_NAME} from configuration #{CONF_DIR}"
      new_collection = solr_instance.create(dir: CONF_DIR, name: COLLECTION_NAME)
      info 'Collection created'
      new_collection
    end

    def start_new_instance
      info "Starting Solr #{SOLR_VERSION} on port #{port}"
      instance = SolrWrapper.instance(verbose: true, port: port, version: SOLR_VERSION)
      instance.start
      info 'Solr started'
      instance
    end

    def port
      config[:port]
    end

    def config
      @config ||= begin
        blacklight_config = YAML.safe_load(File.read(BLACKLIGHT_YML))['test']
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
end
