require 'stash_engine'
require 'stash_datacite'
require 'datacite/mapping/datacite_xml_builder'

module Stash
  module Merritt
    module Package
      class SubmissionPackage
        attr_reader :resource_id

        def initialize(resource_id)
          @resource_id = resource_id
        end

        def resource
          @resource ||= StashEngine::Resource.find(resource_id)
        end

        def to_s
          "#{self.class}: submission package for resource #{resource_id}"
        end

        def uploads
          @uploads ||= begin
            resource.current_file_uploads.map do |u|
              {name: u.upload_file_name, type: u.upload_content_type, size: u.upload_file_size}
            end
          end
        end

        def total_size_bytes
          @total_size_bytes ||= uploads.inject(0) { |sum, upload| sum + upload[:size] }
        end

        def version_number
          @version_number ||= resource.version_number
        end

        def datacite_xml_builder
          @datacite_xml_builder ||= begin
            DataciteXMLBuilder.new(
                doi_value: resource.identifier_value,
                se_resource: resource,
                total_size_bytes: total_size_bytes,
                version: version_number
            )
          end
        end

        def datacite_3_xml_str
          @datacite_3_xml_str ||= begin
            datacite_xml_builder.build_datacite_xml(datacite_3: true)
          end
        end
        
        def datacite_4_xml_str
          @datacite_4_xml_str ||= begin
            datacite_xml_builder.build_datacite_xml
          end
        end

        def stash_wrapper_xml
          # TODO
        end

        def oai_dc_xml
          # TODO
        end

        def dataone_manifest_txt
          # TODO
        end

        def mrt_delete_txt
          # TODO
        end

        def archive_zip
          # TODO
        end

        def cleanup
          # TODO
        end

      end
    end
  end
end
