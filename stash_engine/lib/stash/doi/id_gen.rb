# instantiate IdGen with make_class and
# call mint_id and update_metadata for it to choose and mint the right types of ids based on tenant config
#
# Instance of this class is really never used directly by outside code, but one of the subclasses is used.
# require 'stash/doi/datacite_gen'
# require 'stash/doi/ezid_gen'

module Stash
  module Doi
    class IdGen
      attr_reader :resource

      delegate :url_helpers, to: 'Rails.application.routes'

      # this is to take the place of the normal initialize to create a class of the correct type
      def self.make_instance(resource:)
        id_svc = resource.tenant.identifier_service
        if id_svc.provider == 'ezid'
          EzidGen.new(resource: resource)
        elsif id_svc.provider == 'datacite'
          DataciteGen.new(resource: resource)
        end
      end

      # select correct identifier service class based on resource (and tenant) and mint an id
      def self.mint_id(resource:)
        id_gen = make_instance(resource: resource)
        id_gen.mint_id
      end

      # rubocop:disable Metrics/AbcSize
      # The method reserves a DOI if needed for a specified DOI or minting one from the pool
      # TODO: I don't see this used anywhere.  Delete if it's not used.  Seems to be resource.ensure_identifier, instead?  Or maybe not.
      def ensure_identifier
        # ensure an existing identifier is reserved (if needed for EZID)
        if resource.identifier && resource.identifier.identifier # if identifier has value
          log_info("ensuring identifier is reserved for resource #{resource.id}, ident: #{resource.identifier}")
          return resource.identifier.to_s if resource.skip_datacite_update
          return reserve_id(doi: resource.identifier.to_s) # reserve_id is smart and doesn't reserve again if it already exists
        end
        # otherwise create a new one
        log_info("minting new identifier for resource #{resource.id}")
        resource.ensure_identifier(mint_id)
      end
      # rubocop:enable Metrics/AbcSize

      def update_identifier_metadata!
        log_info("updating identifier landing page (#{landing_page_url}) and metadata for resource #{resource_id} (#{resource.identifier_str})")
        sp = Stash::Merritt::SubmissionPackage.new(resource: resource, packaging: nil)
        dc4_xml = sp.dc4_builder.contents
        update_metadata(dc4_xml: dc4_xml, landing_page_url: landing_page_url) unless resource.skip_datacite_update
      end

      def landing_page_url
        @landing_page_url ||= begin
          path_to_landing = url_helpers.show_path(resource.identifier_str)
          tenant.full_url(path_to_landing)
        end
      end

      def initialize(resource:)
        @resource = resource
      end

      def log_info(message)
        Rails.logger.info("#{Time.now.xmlschema} #{self.class}: #{message}")
      end

      # subclasses should implement mint_id and update_metadata(dc4_xml:, landing_page_url:) methods
      private

      def tenant
        resource.tenant
      end

      def id_params
        @id_params ||= tenant.identifier_service
      end

      def owner
        id_params.owner
      end

      def password
        id_params.password
      end

      def account
        id_params.account
      end

    end
  end
end
