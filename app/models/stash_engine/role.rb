module StashEngine
  class Role < ApplicationRecord
    self.table_name = 'stash_engine_roles'
    belongs_to :user, class_name: 'User'
    belongs_to :role_object, polymorphic: true, optional: true

    # only join after relevant scopes for query efficiency
    belongs_to :tenant, class_name: 'StashEngine::Tenant', foreign_key: 'role_object_id', optional: true
    belongs_to :journal, class_name: 'StashEngine::Journal', foreign_key: 'role_object_id', optional: true
    belongs_to :journal_organization, class_name: 'StashEngine::JournalOrganization', foreign_key: 'role_object_id', optional: true
    belongs_to :funder, class_name: 'StashEngine::Funder', foreign_key: 'role_object_id', optional: true

    scope :tenant_roles, -> { where(role_object_type: 'StashEngine::Tenant') }
    scope :funder_roles, -> { where(role_object_type: 'StashEngine::Funder') }
    scope :journal_roles, -> { where(role_object_type: 'StashEngine::Journal') }
    scope :journal_org_roles, -> { where(role_object_type: 'StashEngine::JournalOrganization') }

    scope :admin, -> { where(role: 'admin') }
    scope :curator, -> { where(role: 'curator') }
    scope :superuser, -> { where(role: 'superuser') }

    scope :admin_roles, -> { admin.where(role_object_id: nil) }
    scope :curator_roles, -> { curator.where(role_object_id: nil) }
    scope :superuser_roles, -> { superuser.where(role_object_id: nil) }

  end
end
