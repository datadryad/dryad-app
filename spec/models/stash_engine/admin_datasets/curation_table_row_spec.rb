# it seems like Brian never made any tests for this class, so putting it in main app tests because
# we have to make extensive data to test and it crosses both engines
require 'rails_helper'

module StashEngine
  module AdminDatasets
    RSpec.describe CurationTableRow, type: :model do

      describe 'admin_generous_results' do

        before(:each) do
          # need resource, user, identifier
          @identifiers = []
          3.times do
            user = create(:user, tenant_id: 'ucop', role: nil)
            identifier = create(:identifier)
            resource = create(:resource, user_id: user.id, tenant_id: user.tenant_id, identifier_id: identifier.id)
            create(:version, resource_id: resource.id)
            @identifiers.push(identifier)
          end
          @identifiers[0].resources.first.update(tenant_id: 'ucop')
          @identifiers[1].resources.first.update(tenant_id: 'localhost')
          @identifiers[2].resources.first.update(tenant_id: 'localhost')
          @tenant = StashEngine::Tenant.find('ucop')
        end

        it "returns records only matching tenant_id when author RORs aren't set" do
          @datasets = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: @tenant)
          # this should only return the first dataset which belongs to the ucop tenant
          expect(@datasets.length).to eql(1)
        end

        it 'returns both matching tenant results AND authors with RORs for a partner' do
          # make this random author claim to be part of this institution though not submitted under it
          @identifiers.second.resources.first.authors.first.affiliations.first.update(ror_id: @tenant.ror_ids.first)

          @datasets = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: @tenant)
          # this should include both tenant_ids and rors for this admin
          expect(@datasets.length).to eql(2)
        end

        it "doesn't duplicate results when multiple authors are from same ROR affiliation" do
          @identifiers.second.resources.first.authors << create(:author)
          @identifiers.second.resources.first.authors.first.affiliations.first.update(ror_id: @tenant.ror_ids.first)
          @identifiers.second.resources.first.authors.second.affiliations.first.update(ror_id: @tenant.ror_ids.first)

          @datasets = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: @tenant)
          expect(@datasets.length).to eql(2)
        end

        it 'returns only one record when id requested specifically' do
          dataset = StashEngine::AdminDatasets::CurationTableRow.where(params: {}, tenant: nil,
                                                                       identifier_id: @identifiers[1].id).first
          expect(dataset.identifier_id).to eq(@identifiers[1].id)
        end
      end
    end
  end
end
