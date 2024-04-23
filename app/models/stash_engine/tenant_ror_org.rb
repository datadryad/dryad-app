module StashEngine
  class TenantRorOrg < ApplicationRecord
    self.table_name = 'stash_engine_tenant_ror_orgs'
    belongs_to :tenant, class_name: 'StashEngine::Tenant'
    belongs_to :ror_org, class_name: 'StashEngine::RorOrg', primary_key: 'ror_id', foreign_key: 'ror_id', optional: true
  end
end
