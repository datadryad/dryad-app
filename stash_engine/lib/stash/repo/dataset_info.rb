require 'nokogiri'

module Stash
  module Repo
    class DatasetInfo

      attr_reader :identifier, :resource, :tenant

      # takes an activerecord identifier object
      def initialize(identifier)
        @identifier = identifier
        @resource = identifier.last_submitted_resource
        @tenant = @resource.tenant
      end

      def manifest
        return @manifest if @manifest
        protodomain, id = @resource.merritt_protodomain_and_local_id
        url = "#{protodomain}/dm/#{id}"
        resp = HttpClient.new(tenant: tenant).client.get(url, follow_redirect: true)
        return nil unless resp.http_header.status_code == 200
        @manifest = resp.body
      rescue SocketError => ex
        nil
      end

      def dataset_size
        return nil unless manifest
        doc = Nokogiri(manifest)
        doc.remove_namespaces!
        elements = doc.xpath('/objectInfo/object/actualSize')
        return nil if elements.blank?
        element = elements.first
        element.content.to_i
      end

    end
  end
end
