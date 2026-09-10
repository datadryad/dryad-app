# == Schema Information
#
# Table name: stash_engine_tenant_ror_orgs
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ror_id     :string(191)
#  tenant_id  :string(191)
#
# Indexes
#
#  index_stash_engine_tenant_ror_orgs_on_tenant_id_and_ror_id  (tenant_id,ror_id)
#
module StashEngine
  class TenantRorOrg < ApplicationRecord
    self.table_name = 'stash_engine_tenant_ror_orgs'
    belongs_to :tenant, class_name: 'StashEngine::Tenant'
    belongs_to :ror_org, class_name: 'StashEngine::RorOrg', primary_key: 'ror_id', foreign_key: 'ror_id', optional: true
  end
end
