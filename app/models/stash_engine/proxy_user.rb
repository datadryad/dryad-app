# == Schema Information
#
# Table name: stash_engine_users
#
#  id               :integer          not null, primary key
#  email            :text(65535)
#  first_name       :text(65535)
#  last_login       :datetime
#  last_name        :text(65535)
#  migration_token  :string(191)
#  old_dryad_email  :string(191)
#  orcid            :string(191)
#  tenant_auth_date :datetime
#  validated        :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  affiliation_id   :integer
#  eperson_id       :integer
#  tenant_id        :text(65535)
#
# Indexes
#
#  index_stash_engine_users_on_affiliation_id  (affiliation_id)
#  index_stash_engine_users_on_email           (email)
#  index_stash_engine_users_on_orcid           (orcid)
#  index_stash_engine_users_on_tenant_id       (tenant_id)
#
module StashEngine

  # Roleless user for API proxy
  class ProxyUser < ApplicationRecord
    self.table_name = 'stash_engine_users'
    has_many :roles, -> { where.not(role_object_type: nil) }, foreign_key: :user_id
    has_many :resources, through: :roles, source: :role_object, source_type: 'StashEngine::Resource'
    has_many :journals, through: :roles, source: :role_object, source_type: 'StashEngine::Journal'
    has_many :journal_organizations, through: :roles, source: :role_object, source_type: 'StashEngine::JournalOrganization'
    has_many :funders, through: :roles, source: :role_object, source_type: 'StashEngine::Funder'
    has_many :tenants, through: :roles, source: :role_object, source_type: 'StashEngine::Tenant'
    belongs_to :affiliation, class_name: 'StashDatacite::Affiliation', optional: true
    belongs_to :tenant, class_name: 'StashEngine::Tenant', optional: true

    has_many :access_grants,
             class_name: 'Doorkeeper::AccessGrant',
             foreign_key: :resource_owner_id,
             dependent: :delete_all # or :destroy if you need callbacks

    has_many :access_tokens,
             class_name: 'Doorkeeper::AccessToken',
             foreign_key: :resource_owner_id,
             dependent: :delete_all # or :destroy if you need callbacks

    def self.from_omniauth_orcid(auth_hash:, emails:)
      users = find_by_orcid_or_emails(orcid: auth_hash[:uid], emails: emails)

      # If multiple user accounts respond to this ORCID/email, there is a legacy account
      # that didn't have an ORCID, or the user recently added an email to their ORCID profile,
      # so we will merge the accounts.
      while users.count > 1
        target_user = users.first
        merging_user = users.second
        target_user.merge_user!(other_user: merging_user)
        merging_user.destroy
        users = find_by_orcid_or_emails(orcid: auth_hash[:uid], emails: emails)
      end

      return users.first.update_user_orcid(orcid: auth_hash[:uid], temp_email: emails.try(:first)) if users.count == 1

      create_user_with_orcid(auth_hash: auth_hash, temp_email: emails.try(:first))
    end

    def self.find_by_orcid_or_emails(orcid:, emails:)
      emails = Array.wrap(emails)
      emails.delete_if(&:blank?)
      StashEngine::ApiUser.where(['orcid = ? or email IN ( ? )', orcid, emails])
    end

    def name
      "#{first_name} #{last_name}".strip
    end

    def name_last_first
      [last_name, first_name].join(', ')
    end

    def tenant_limited?
      roles.tenant_roles.present?
    end

    def admin? = false
    def curator? = false
    def superuser? = false
    def min_admin? = false
    def min_app_admin? = false
    def min_curator? = false

    def journals_as_admin
      admin_org_journals = journal_organizations.map(&:journals_sponsored).flatten
      (journals + admin_org_journals).uniq
    end

    def self.split_name(name)
      comma_split = name.split(',')
      return [comma_split[1].strip, comma_split[0].strip] if comma_split.length == 2 # gets a reversed name with comma like "Janee, Greg"

      first = (name.split.first || '').strip
      last = ''
      last = name.split.last unless name.split.last == first
      [first, last]
    end

    def tenant
      Tenant.find(tenant_id)
    end

  end

end
