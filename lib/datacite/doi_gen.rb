module Datacite
  class DoiGenError < StandardError; end
  class DataciteError < DoiGenError; end

  class DoiGen
    attr_reader :resource

    def initialize(resource:)
      @resource = resource
    end

    def self.mint_id(resource:)
      datacite_gen = DoiGen.new(resource: resource)
      datacite_gen.mint_id
    end

    # @return [String] the identifier (DOI, ARK, or URN)
    def mint_id
      base_id = "#{APP_CONFIG[:identifier_service][:prefix]}/dryad.#{StashEngine::NoidState.mint}"
      "doi:#{base_id}"
    end

    # we are not reserving ahead with datacite, so just return the DOI
    def reserve_id(doi:)
      doi
    end

    # The method reserves a DOI if needed for a specified DOI or minting one from the pool.
    # submission to be sure a (minted if needed) stash_engine_identifier exists with the ID filled in before doing fun stuff
    def ensure_identifier
      # ensure an existing identifier is reserved (if needed for EZID)
      return resource.identifier.to_s if resource&.identifier&.identifier.present?

      resource.ensure_identifier(mint_id)
    end

    def update_identifier_metadata!
      log_info("updating identifier landing page (#{landing_page_url}) and metadata for resource #{resource.id} (#{resource.identifier_str})")
      update_metadata(dc4_xml: dc4_contents, landing_page_url: landing_page_url) unless resource.skip_datacite_update
    end

    def landing_page_url
      @landing_page_url ||= Rails.application.routes.url_helpers.show_url(resource.identifier_str)&.gsub(%r{^http://}, 'https://')
    end

    def log_info(message)
      Rails.logger.info("#{Time.now.utc.xmlschema} #{self.class}: #{message}")
    end

    def ping(identifier)
      get_doi(identifier, username: account, password: password, sandbox: sandbox)
    end

    def update_metadata(dc4_xml:, landing_page_url:)
      # add breakpoint here to get a peek at the XML being sent to DataCite
      # the doi apparently is known from the DC xml document
      response = post_metadata(dc4_xml)
      validate_response(response: response, operation: 'update metadata')

      response = put_doi(bare_identifier, landing_page_url)
      validate_response(response: response, operation: 'update target')
    rescue HTTP::Error => e
      err = DataciteError.new("Datacite failed to update metadata for resource #{resource&.identifier_str} " \
                              "(#{e.message}) with params: #{dc4_xml.inspect}")
      err.set_backtrace(e.backtrace) if e.backtrace.present?
      raise err
    end

    private

    def dc4_contents
      @dc4_contents ||= dc4_builder.build_resource&.write_xml
    end

    def dc4_builder
      @dc4_builder ||= Datacite::Mapping::DataciteXMLFactory.new(
        doi_value: resource.identifier_value,
        se_resource_id: resource.id,
        total_size_bytes: resource.identifier.storage_size,
        version: resource.version_number
      )
    end

    # strip off the icky doi: at the first
    def bare_identifier
      resource.identifier_str.gsub(/^doi:/, '')
    end

    def prefix
      id_params.prefix
    end

    def sandbox
      id_params.sandbox
    end

    def validate_response(response:, operation:)
      raise DataciteError, "DataCite failed to #{operation} for resource #{@resource&.id} -- #{response.inspect}" unless response.status == 201
    end

    def post_metadata(data)
      url = "#{mds_url}/metadata"
      headers = { content_type: 'application/xml;charset=UTF-8' }
      Integrations::Datacite.http.post(url, headers: headers, body: data)
    end

    def put_doi(doi, url)
      payload = "doi=#{doi}\nurl=#{url}"
      url = "#{mds_url}/doi/#{doi}"
      headers = { content_type: 'application/xml;charset=UTF-8' }
      Integrations::Datacite.http.put(url, headers: headers, body: payload)
    end

    def get_doi(doi)
      url = "#{mds_url}/doi/#{doi}"
      Integrations::Datacite.http.get(url)
    end

    def mds_url
      APP_CONFIG[:identifier_service][:mds]
    end
  end
end
