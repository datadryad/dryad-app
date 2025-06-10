# frozen_string_literal: true

class AddAuthDate < ActiveRecord::Migration[8.0]
  def up
    StashEngine::User.where.not(tenant_id: 'dryad').each {|u| u.update(tenant_auth_date: u.last_login)}
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
