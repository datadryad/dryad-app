require 'ezid/client'
require 'http'

module Tasks
  module EzidTransition
    module Register

      SAMPLE_DC4_XML = <<~XML.freeze
        <resource
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://datacite.org/schema/kernel-4" xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd">
            <identifier identifierType="DOI">10.7959/S85H-9D15</identifier>
            <creators>
                <creator>
                    <creatorName nameType="Organizational">Dryad Digital Repository</creatorName>
                    <affiliation affiliationIdentifier="https://ror.org/00x6h5n95" affiliationIdentifierScheme="ROR" schemeURI="https://ror.org">Dryad Digital Repository</affiliation>
                </creator>
            </creators>
            <titles>
                <title xml:lang="en">Dryad dataset awaiting publication</title>
            </titles>
            <publisher>Dryad</publisher>
            <publicationYear>2023</publicationYear>
            <resourceType resourceTypeGeneral="Dataset">Dataset</resourceType>
            <sizes/>
            <formats/>
            <version/>
            <descriptions>
                <description descriptionType="Abstract">:unas</description>
            </descriptions>
        </resource>
      XML

      def self.register_doi(doi:)
        doi.gsub!(/^doi:/, '') # strip off the icky doi: at the first if it's there

        # find correct tenant from DOI and latest resource
        stash_identifier = StashEngine::Identifier.find_by(identifier: doi)
        resource = stash_identifier&.latest_resource
        if stash_identifier.nil? || resource.nil?
          puts "  Couldn't find dryad identifier or resource for #{doi}, will not update"
          return
        end

        id_svc = resource.tenant.identifier_service
        if id_svc.provider != 'ezid' || doi.start_with?(APP_CONFIG.identifier_service.prefix)
          puts "  Not an EZID identifier for #{doi}, will not update"
          return
        end

        if self.status(doi: doi) != 'reserved'
          puts "  Not reserved, so not updating #{doi}"
          return
        end

        # Make the EZID client stop spamming information messages to standard out, seems to be hard coded somehow and
        # not follow the logging level elsewhere.
        ::Ezid::Client.configure do |config|
          config.logger = Logger.new(File::NULL)
        end
        ezid_client = ::Ezid::Client.new(host: APP_CONFIG.ezid.host, port: APP_CONFIG.ezid.port, user: id_svc.account, password: id_svc.password)

        params = { status: 'public', datacite: SAMPLE_DC4_XML.gsub('10.7959/S85H-9D15', doi) }
        params[:owner] = id_svc.owner unless id_svc.owner.blank?
        params[:target] = 'https://datadryad.org' # generic URL for our repository, but nothing else

        begin
          ezid_client.modify_identifier(resource.identifier_str, **params)
        rescue Ezid::Error => e
          puts "  Ezid failed to update metadata for resource #{resource&.identifier_str} (#{e.message}) with params: #{params.inspect}"
          puts e.backtrace.join("\n  ")
          return
        end
        puts "  Updated placeholder metadata at EZID for #{doi}"
      end

      # we want status to be 'reserved' for the update to take place
      def self.status(doi:)
        resp = HTTP.accept('text/plain').timeout(15).get("https://ezid.cdlib.org/id/doi:#{doi}")
        ezid_status = if resp.status == 200
                        ezid_info = resp.body.to_s
                        ezid_info.match(/^_status: (\S+)$/)[1]
                      elsif resp.status == 400
                        'not_found'
                      end

        ezid_status
      end
    end
  end
end
