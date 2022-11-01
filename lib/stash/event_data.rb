# EventData is the DataCite API for getting stats about citations and usage.
# They currently do not have totals so we need to get large swaths of data and add it up on the client side instead
# of doing it a database where it is probably easier and more efficient.
require 'http'
require 'cgi'

module Stash
  module EventData

    class QueryFailure < RuntimeError; end

    Dir.glob(File.expand_path('event_data/*.rb', __dir__)).sort.each(&method(:require))

    TIME_BETWEEN_RETRIES = 1
    def logger
      Rails.logger
    end

    # These methods are mixed in to citations and usage classes
    protected

    def generic_query(url:, params: {})
      http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 60, read: 60).timeout(60).follow(max_hops: 10)

      # get any pre-existing hash off query-part of url
      uri_obj = URI.parse(url)
      existing_params = CGI.parse(uri_obj.query || '')
      existing_params.each { |key, val| existing_params[key] = val.first } # because CGI makes every value into an array

      uri_begin = "#{uri_obj.scheme}://#{uri_obj.host}:#{uri_obj.port}#{uri_obj.path}"

      hash = { 'mailto' => @email }.merge(existing_params)
      r = make_reliable { http.get uri_begin, params: hash.merge(params) }

      resp = r.parse if r.headers['content-type'].start_with?('application/json') && r.code != 204 # 204 is no-content
      resp = resp.with_indifferent_access if resp.instance_of?(Hash)
      resp
    end

    def make_reliable
      resp = nil
      4.downto(0) do |my_retry|
        resp = yield
        return resp if resp.status.success?
      rescue HTTP::Error, JSON::ParserError => e
        raise QueryFailure, "Error from HTTP #{resp&.uri}\nOriginal error: #{e}\n#{e.full_message}" if my_retry < 1

        sleep TIME_BETWEEN_RETRIES
      end
      # if it has tried 5 times without success, then raise error
      raise QueryFailure, "Error from HTTP #{resp&.uri} -- got status code #{resp&.status&.code}"
    end
  end
end
