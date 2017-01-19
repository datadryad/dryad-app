require 'stash/repo'

module Stash
  module Merritt
    module Sword
      class SwordTask < Stash::Repo::Task
        attr_reader :package

        def initialize(package:)
          @package = package
        end

        def exec
          log.debug("#{self.class}: Submitting #{zipfile} for '#{package.resource_title}' (#{resource.identifier_str}) (id: #{resource.id}) at #{Time.now} with sword_params: #{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}")
          if (update_uri = resource.update_uri)
            sword_client.update(edit_iri: update_uri, zipfile: zipfile)
          else
            sword_client.create(doi: resource.identifier_str, zipfile: zipfile)
          end
        end

        private

        def resource
          package.resource
        end

        def zipfile
          package.zipfile
        end

        def tenant
          resource.tenant
        end

        def sword_params
          tenant.sword_params
        end

        def sword_client
          Stash::Sword::Client.new(logger: log, **sword_params)
        end
      end
    end
  end
end
