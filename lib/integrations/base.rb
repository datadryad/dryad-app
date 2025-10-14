module Integrations
  class Base

    def search_award(award_id)
      search_awards [award_id]
    end

    private

    def post_json(url, payload)
      uri          = URI.parse(url)
      http         = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request      = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/vnd.api+json' })
      request.body = payload.to_json

      parse_response(http.request(request))
    end

    def get_json(url, payload)
      uri       = URI(url)
      uri.query = URI.encode_www_form(payload)

      response = Net::HTTP.get_response(uri)
      parse_response(response)
    end

    def get_xml(url, payload)
      uri       = URI(url)
      uri.query = URI.encode_www_form(payload)

      response = Net::HTTP.get_response(uri)
      parse_response(response, format: :xml)
    end

    def parse_response(response, format: :json)
      raise StandardError, "Bad response status: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      return Nokogiri::XML::Document.parse(response.body) if format == :xml

      JSON.parse(response.body)
    end
  end
end
