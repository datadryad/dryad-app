require 'db_spec_helper'

module Stash
  module Merritt
    module Builders
      describe MerrittOAIDCBuilder do
        attr_reader :resource
        attr_reader :tenant

        before(:each) do
          user = StashEngine::User.create(
            uid: 'lmuckenhaupt-example@example.edu',
            email: 'lmuckenhaupt@example.edu',
            tenant_id: 'dataone'
          )

          dc4_xml = File.read('spec/data/archive/mrt-datacite.xml')
          dcs_resource = Datacite::Mapping::Resource.parse_xml(dc4_xml)
          stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
          stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

          @tenant = double(StashEngine::Tenant)
          allow(tenant).to receive(:short_name).and_return('DataONE')
          allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)

          @resource = StashDatacite::ResourceBuilder.new(
            user_id: user.id,
            dcs_resource: dcs_resource,
            stash_files: stash_wrapper.inventory.files,
            upload_date: stash_wrapper.version_date,
            tenant_id: 'dataone'
          ).build
          allow(@resource).to receive(:tenant).and_return(@tenant)
        end

        describe '#build_xml_string' do
          it 'includes related identifiers' do
            rel_ids = StashDatacite::RelatedIdentifier::RelationTypesLimited.values.map do |rel_type|
              related_doi_value = "10.5555/#{Time.now.nsec}"
              StashDatacite::RelatedIdentifier.create(
                resource_id: resource.id,
                relation_type: rel_type,
                related_identifier_type: 'doi',
                related_identifier: related_doi_value
              )
            end

            expected = {
              'IsPartOf' => 'isPartOf',
              'HasPart' => 'hasPart',
              'IsCitedBy' => 'isReferencedBy',
              'Cites' => 'references',
              'IsReferencedBy' => 'isReferencedBy',
              'References' => 'references',
              'IsNewVersionOf' => 'isVersionOf',
              'IsPreviousVersionOf' => 'hasVersion',
              'IsVariantFormOf' => 'isVersionOf',
              'IsOriginalFormOf' => 'hasVersion'
            }

            dc_builder = MerrittOAIDCBuilder.new(resource_id: resource.id)
            xml_string = dc_builder.contents
            rel_ids.each do |rel_id|
              predicate = expected[rel_id.relation_type_friendly] || 'relation'
              dc_tag = "dcterms:#{predicate}"
              id_value = "#{rel_id.related_identifier_type_friendly}: #{rel_id.related_identifier}"
              expect(xml_string).to include("<#{dc_tag}>#{id_value}</#{dc_tag}>")
            end
          end
        end
      end
    end
  end
end
