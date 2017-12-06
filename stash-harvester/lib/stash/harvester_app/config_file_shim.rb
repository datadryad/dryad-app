require 'yaml'

module Stash
  module HarvesterApp
    class ConfigFileShim
      attr_accessor :config_file, :settings, :configs, :tempfiles

      def initialize(config_file)
        @config_file = config_file
        validate_config_basics
        setup_configs
      end

      # free any references for temp files created
      def cleanup
        @tempfiles = nil
      end

      private

      def validate_config_basics
        raise ConfigFileShimError, 'config file does not exist' unless File.exist?(@config_file)
        raise ConfigFileShimError, 'STASH_ENV environment variable not set' unless ENV['STASH_ENV']
        raise ConfigFileShimError, "No #{ENV['STASH_ENV']} section exists in your config file" unless YAML.load_file(@config_file)[ENV['STASH_ENV']]
      end

      def setup_configs
        @settings = YAML.load_file(@config_file)[ENV['STASH_ENV']]
        unless @settings['source'] && @settings['source']['sets']
          @configs = [config_file]
          return
        end
        make_new_configs
      end

      def make_new_configs
        sets = @settings['source']['sets']
        sets.map! do |set|
          tmp = Marshal.load(Marshal.dump(@settings)) # deep clone
          tmp['source'].delete('sets')
          tmp['source']['set'] = set
          tmp['db']['database'] = "db/#{set}.sqlite3"
          { ENV['STASH_ENV'] => tmp }
        end
        make_tempfiles(sets)
      end

      def make_tempfiles(confs)
        @tempfiles = confs.map do |conf|
          tf = Tempfile.new('harvest')
          tf.write conf.to_yaml
          tf.close
          tf
        end
        @configs = @tempfiles.map(&:path)
      end
    end

    class ConfigFileShimError < StandardError; end
  end
end
