require 'nokogiri'

module Stash
  module Repo
    class DatasetInfo

      TIMEOUT = 300 # 5 minutes, merritt is slow

      attr_reader :identifier, :resource, :tenant

      # takes an activerecord identifier object
      def initialize(identifier)
        @resource = nil
        @tenant = nil
        @identifier = identifier
        @resource = identifier.last_submitted_resource
        @tenant = @resource.tenant if @resource
      end

      # rubocop:disable Metrics/MethodLength
      def manifest
        return @manifest if @manifest
        return nil unless @resource && @tenant
        protodomain, id = @resource.merritt_protodomain_and_local_id
        url = "#{protodomain}/dm/#{id}"
        client = HttpClient.new(tenant: tenant).client
        timeouts(client)
        resp = client.get(url, follow_redirect: true)
        return nil unless resp.http_header.status_code == 200
        @manifest = resp.body
      rescue SocketError, HTTPClient::ReceiveTimeoutError => ex
        puts ex
        nil
      end
      # rubocop:enable Metrics/MethodLength

      def nokogiri_doc
        return @nokogiri_doc if @nokogiri_doc
        @nokogiri_doc = Nokogiri(manifest)
        @nokogiri_doc.remove_namespaces!
        @nokogiri_doc
      end

      def dataset_size
        return nil unless manifest
        elements = nokogiri_doc.xpath('/objectInfo/object/actualSize')
        return nil if elements.blank?
        element = elements.first
        element.content.to_i
      end

      def file_size(filename)
        return 0 unless manifest
        ick = xpath_escape_quotes("producer/#{filename}")
        xp = "/objectInfo/versions/version[@id='#{@resource.stash_version.merritt_version}']/manifest/file[@id=#{ick}]/size"
        elements = nokogiri_doc.xpath(xp)
        return nil if elements.blank?
        element = elements.first
        element.content.to_i
      end

      def timeouts(client)
        client.connect_timeout = TIMEOUT
        client.send_timeout = TIMEOUT
        client.receive_timeout = TIMEOUT
        client.keep_alive_timeout = TIMEOUT
      end

      private

      def xpath_escape_quotes(fn)
        return "\"#{fn}\"" unless fn.include?('"') # just double quote it unless it contains a double quote
        # otherwise do this crazy replacement to make sure every type of quote is enclosed in its opposite and makes an XPATH contact function
        "concat('" + fn.gsub(/['\"]/){|i| (i == '"' ? %{', '"', '} : %{', "'", '}) } + "')"
      end

    end
  end
end
