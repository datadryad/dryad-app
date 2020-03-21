require 'http'
require 'byebug'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, file_collection:)
# The zenodo newversion seems to be editing the same deposition id
# 503933

module Stash
  module ZenodoReplicate

    class ZenodoError < StandardError; end

    module ZenodoConnection

      # checks that can access API with token and return boolean
      def self.validate_access
        standard_request(:get, "#{base_url}/api/deposit/depositions")
        true
      rescue ZenodoError
        false
      end

      def self.standard_request(method, url, **args)
        http = HTTP.timeout(connect: 30, read: 60).timeout(7200).follow(max_hops: 10)

        my_params = { access_token: APP_CONFIG[:zenodo][:access_token] }.merge(args.fetch(:params, {}))
        my_headers = { 'Content-Type': 'application/json' }.merge(args.fetch(:headers, {}))
        my_args = args.merge(params: my_params, headers: my_headers)

        r = http.send(method, url, my_args)

        resp = r.parse
        resp = resp.with_indifferent_access if resp.class == Hash

        unless r.status.success?
          raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}"
        end
        resp
      rescue HTTP::Error => e
        raise ZenodoError, "Error from HTTP #{method} #{url}\nOriginal error: #{e}\n#{e.backtrace.join("\n")}"
      end

      def self.param_merge(p = {})
        { access_token: APP_CONFIG[:zenodo][:access_token] }.merge(p)
      end

      def self.base_url
        APP_CONFIG[:zenodo][:base_url]
      end
    end
  end
end
