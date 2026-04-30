module Integrations
  class Base

    def search_award(award_id)
      search_awards [award_id]
    end

    private

    def post_json(url, payload, headers = {})
      json_update(url, payload, headers, Net::HTTP::Post)
    end

    def put_json(url, payload, headers = {})
      json_update(url, payload, headers, Net::HTTP::Put)
    end

    def get_json(url, payload = nil, headers = nil)
      uri       = URI(url)
      uri.query = URI.encode_www_form(payload) if payload.present?

      response = Net::HTTP.get_response(uri, headers)
      parse_response(response)
    end

    def get_xml(url, payload)
      uri       = URI(url)
      uri.query = URI.encode_www_form(payload)

      response = Net::HTTP.get_response(uri)
      parse_response(response, format: :xml)
    end

    def json_update(url, payload, headers, http_class)
      uri          = URI.parse(url)
      http         = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      headers = headers.merge({ 'Content-Type' => 'application/vnd.api+json' })

      request      = http_class.new(uri.request_uri, headers)
      request.body = payload.to_json

      parse_response(http.request(request))
    end

    def parse_response(response, format: :json)
      if response.is_a?(Net::HTTPBadRequest)
        Rails.logger.info("Bad response status: #{response.code} #{response.message}")
        return
      end

      return Nokogiri::XML::Document.parse(response.body) if format == :xml

      JSON.parse(response.body)
    end

  end
end
