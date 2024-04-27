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
    scope :superuser, -> { where(role: 'superuser', role_object_id: nil) }

    scope :min_admin, -> { where(role: %w[admin curator superuser]) }
    scope :min_app_admin, -> { curator.or(where(role: %w[admin superuser], role_object_id: nil)) }
    scope :min_curator, -> { where(role: %w[curator superuser]) }

  end
end
