module Stash
  module Harvester
    module Solr

      # Configuration for a Solr index.
      class SolrIndexConfig < IndexConfig

        attr_reader :proxy_uri
        attr_reader :opts

        # Constructs a new +SolrIndexConfig+ with the specified properties.
        #
        # @param url [URI, String] The URL of the Solr server
        # @param proxy [URI, String] The URL of any proxy server required
        #   to access the Solr server
        # @param opts [Hash] Additional options to be passed when creating
        #   the Solr client.
        def initialize(url:, proxy: nil, **opts)
          super(url: url)
          @proxy_uri = Util.to_uri(proxy)
          all_opts = opts.clone
          all_opts[:url] = uri.to_s
          all_opts[:proxy] = @proxy_uri.to_s if @proxy_uri
          @opts = all_opts
        end

      end
    end
  end
end
