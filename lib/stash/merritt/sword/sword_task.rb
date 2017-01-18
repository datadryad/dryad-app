require 'stash/repo'

module Stash
  module Merritt
    module Sword
      class SwordTask < Stash::Repo::Task
        attr_reader :sword_params

        def initialize(sword_params:)
          @sword_params = sword_params
        end

        def client
          @client ||= Stash::Sword::Client.new(logger: log, **sword_params)
        end

        # @return [SubmissionPackage] the package
        def exec(package)
          resource = package.resource
          zipfile = package.zipfile
          log.debug("#{self.class}: Submitting #{zipfile} for '#{package.resource_title}' (#{resource.identifier_str}) (id: #{resource.id}) at #{Time.now} with sword_params: #{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}")
          submit(resource, zipfile)
          package
        end

        private

        def submit(resource, zipfile)
          if (update_uri = resource.update_uri)
            client.update(edit_iri: update_uri, zipfile: zipfile)
          else
            client.create(doi: resource.identifier_str, zipfile: zipfile)
          end
        end
      end
    end
  end
end
