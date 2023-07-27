# instantiate IdGen with make_class and
# call mint_id and update_metadata for it to choose and mint the right types of ids based on tenant config
#
# Instance of this class is really never used directly by outside code, but one of the subclasses is used.
# require 'stash/doi/datacite_gen'
# require 'stash/doi/ezid_gen'

module Stash
  module Doi
    class IdGenError < StandardError; end

    class IdGen
      attr_reader :resource

      # this is to take the place of the normal initialize to create a class of the correct type
      def self.make_instance(resource:)
        id_svc = resource.tenant.identifier_service.provider
        id_info = resource&.identifier&.identifier

        # make it datacite for items that aren't actively EZID already
        id_svc = 'datacite' if id_info.blank? || id_info.start_with?(APP_CONFIG[:identifier_service][:prefix])

        case id_svc
        when 'ezid'
          EzidGen.new(resource: resource)
        when 'datacite'
          DataciteGen.new(resource: resource)
        end
      end

      # select correct identifier service class based on resource (and tenant) and mint an id
      def self.mint_id(resource:)
        id_gen = make_instance(resource: resource)
        id_gen.mint_id
      end

      # @return [String] the identifier (DOI, ARK, or URN)
      def mint_id
        base_id = "#{APP_CONFIG[:identifier_service][:prefix]}/dryad.#{StashEngine::NoidState.mint}"
        "doi:#{base_id}"
      end

      # reserve DOI in string format like "doi:xx.xxx/yyyyy" and return ID string after reserving it.
      # I don't believe DataCite does the reserving thing like EZID, but this kept the interface consistent.
      def reserve_id(doi:)
        doi
      end

      # The method reserves a DOI if needed for a specified DOI or minting one from the pool.  (formerly?) used by Merritt
      # submission to be sure a (minted if needed) stash_engine_identifier exists with the ID filled in before doing fun stuff
      def ensure_identifier
        # ensure an existing identifier is reserved (if needed for EZID)
        return resource.identifier.to_s if resource&.identifier&.identifier.present?

        resource.ensure_identifier(mint_id)
      end

      def update_identifier_metadata!
        log_info("updating identifier landing page (#{landing_page_url}) and metadata for resource #{resource.id} (#{resource.identifier_str})")
        sp = Stash::Merritt::SubmissionPackage.new(resource: resource, packaging: nil)
        dc4_xml = sp.dc4_builder.contents
        update_metadata(dc4_xml: dc4_xml, landing_page_url: landing_page_url) unless resource.skip_datacite_update
      end

      def landing_page_url
        @landing_page_url ||= Rails.application.routes.url_helpers.show_url(resource.identifier_str)&.gsub(%r{^http://}, 'https://')
      end

      def initialize(resource:)
        @resource = resource
      end

      def log_info(message)
        Rails.logger.info("#{Time.now.utc.xmlschema} #{self.class}: #{message}")
      end

      # subclasses should implement mint_id and update_metadata(dc4_xml:, landing_page_url:) methods

    end
  end
end
