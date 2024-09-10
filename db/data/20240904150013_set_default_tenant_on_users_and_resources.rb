# frozen_string_literal: true

class SetDefaultTenantOnUsersAndResources < ActiveRecord::Migration[7.0]
  def up
    StashEngine::User.where(tenant_id: nil).update_all(tenant_id: APP_CONFIG.default_tenant)
    StashEngine::Resource.where(tenant_id: nil).each do |r|
      r.update(tenant_id: r.user.tenant_id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
