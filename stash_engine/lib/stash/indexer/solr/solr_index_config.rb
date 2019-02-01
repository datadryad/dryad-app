require 'stash/indexer/index_config'
require 'rsolr'

module Stash
  module Indexer
    module Solr

      # Configuration for a Solr index.
      class SolrIndexConfig

        adapter 'Solr'

        SUSPICIOUS_OPTS = { proxy_url: :proxy, proxy_uri: :proxy }.freeze
        private_constant :SUSPICIOUS_OPTS

        attr_reader :proxy_uri
        attr_reader :opts

        # Constructs a new `SolrIndexConfig` with the specified properties.
        #
        # @param url [URI, String] The URL of the Solr core, e.g.
        #   `http://solr.example.org:8983/solr/stash`
        # @param proxy [URI, String] The URL of any proxy server required
        #   to access the Solr server
        # @param opts [Hash] Additional options to be passed when creating
        #   the [RSolr](https://github.com/rsolr/rsolr) client.
        def initialize(url:, proxy: nil, **opts)
          super(url: url)
          check_opts(opts)

          @proxy_uri = Util.to_uri(proxy)
          all_opts = opts.clone
          all_opts[:url] = uri.to_s
          all_opts[:proxy] = @proxy_uri.to_s if @proxy_uri
          @opts = all_opts
        end

        # Creates a new `SolrIndexer` with this configuration.
        def create_indexer(metadata_mapper)
          SolrIndexer.new(config: self, metadata_mapper: metadata_mapper)
        end

        def description
          opts_desc = @opts.map { |k, v| "#{k}: #{v}" }.join(', ')
          "#{self.class} (#{opts_desc})"
        end

        private

        def check_opts(opts)
          SUSPICIOUS_OPTS.each do |k, v|
            Indexer.log.warn("#{SolrIndexConfig} initialized with #{k.inspect} => #{opts[k].inspect}. Did you mean #{v.inspect}?") if opts.include?(k)
          end
        end

      end
    end
  end
end
