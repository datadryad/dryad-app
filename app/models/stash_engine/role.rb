# == Schema Information
#
# Table name: stash_engine_roles
#
#  id               :bigint           not null, primary key
#  role             :string(191)
#  role_object_type :string(191)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  role_object_id   :string(191)
#  user_id          :integer
#
# Indexes
#
#  index_stash_engine_roles_on_role_object_type_and_role_object_id  (role_object_type,role_object_id)
#  index_stash_engine_roles_on_user_id                              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => stash_engine_users.id)
#
module StashEngine
  class Role < ApplicationRecord
    self.table_name = 'stash_engine_roles'
    belongs_to :user, class_name: 'StashEngine::User'
    belongs_to :role_object, polymorphic: true, optional: true

    # only join after relevant scopes for query efficiency
    belongs_to :tenant, class_name: 'StashEngine::Tenant', foreign_key: 'role_object_id', optional: true
    belongs_to :journal, class_name: 'StashEngine::Journal', foreign_key: 'role_object_id', optional: true
    belongs_to :journal_organization, class_name: 'StashEngine::JournalOrganization', foreign_key: 'role_object_id', optional: true
    belongs_to :funder, class_name: 'StashEngine::Funder', foreign_key: 'role_object_id', optional: true
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'role_object_id', optional: true

    scope :submission_roles, -> { where(role_object_type: 'StashEngine::Resource') }
    scope :admin_roles, -> { where("role_object_type is null or role_object_type != 'StashEngine::Resource'") }

    scope :system_roles, -> { where(role_object_type: nil) }
    scope :tenant_roles, -> { where(role_object_type: 'StashEngine::Tenant') }
    scope :funder_roles, -> { where(role_object_type: 'StashEngine::Funder') }
    scope :journal_roles, -> { where(role_object_type: 'StashEngine::Journal') }
    scope :journal_org_roles, -> { where(role_object_type: 'StashEngine::JournalOrganization') }

    scope :admin, -> { where(role: 'admin') }
    scope :curator, -> { where(role: 'curator') }
    scope :manager, -> { where(role: 'manager', role_object_id: nil) }
    scope :superuser, -> { where(role: 'superuser', role_object_id: nil) }

  end
end
