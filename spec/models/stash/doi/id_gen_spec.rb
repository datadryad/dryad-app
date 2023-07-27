# require 'ostruct'
#
# module Stash
#   module Doi
#     describe IdGen do
#
#       attr_reader :resource_id
#       attr_reader :resource
#       attr_reader :identifier_str
#       attr_reader :landing_page_url
#       attr_reader :helper
#       attr_reader :url_helpers
#       attr_reader :tenant
#
#       before(:each) do
#         @resource = create(:resource)
#         @resource.identifier.update(identifier: nil)
#       end
#
#       describe :mint_id do
#         it 'needs to allow minting for DataCite DOI (all new should be datacite)' do
#           my_id = IdGen.mint_id(resource: resource)
#           expect(my_id).to be_a_kind_of(String)
#           expect(my_id.include?('/dryad.')).to be true
#         end
#       end
#
#       describe :make_instance do
#         it 'makes a DataCite instance for things without ID yet' do
#           resource.update(tenant_id: 'ucop')
#           inst = IdGen.make_instance(resource: resource)
#           expect(inst).to be_instance_of(Stash::Doi::DataciteGen)
#         end
#
#         it 'makes an EZID instance for existing EZID dois' do
#           resource.update(tenant_id: 'ucop')
#           resource.identifier.update(identifier: '10.18736/F6')
#           inst = IdGen.make_instance(resource: resource)
#           expect(inst).to be_instance_of(Stash::Doi::EzidGen)
#         end
#       end
#
#     end
#   end
# end
