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
#  role             :string
#  validation_tries :integer          default(0)
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
  class User < ApplicationRecord
    self.table_name = 'stash_engine_users'
    has_many :resources
    has_many :roles, dependent: :destroy
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

    accepts_nested_attributes_for :roles

    scope :curators, -> { joins(:roles).where('stash_engine_roles' => { role: 'curator', role_object_id: nil }) }

    scope :min_curators, -> { joins(:roles).where('stash_engine_roles' => { role: %w[superuser curator] }) }

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
      StashEngine::User.where(['orcid = ? or email IN ( ? )', orcid, emails])
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

    def admin?
      roles.admin.present?
    end

    def curator?
      roles.curator.present?
    end

    def superuser?
      roles.superuser.present?
    end

    def system_user?
      roles.system_roles.present?
    end

    def min_admin?
      roles.min_admin.present?
    end

    def min_app_admin?
      roles.min_app_admin.present?
    end

    def min_curator?
      roles.min_curator.present?
    end

    def journals_as_admin
      admin_org_journals = journal_organizations.map(&:journals_sponsored).flatten
      (journals + admin_org_journals).uniq
    end

    # Merges the other user into this user.  Updates so that this user owns other user's old stuff and has their critical info.
    # Also overwrites some selected fields from this user with other user's info which should be more current.
    # The other_user passed in is generally a newly logged in user that is having any of their new stuff transferred into their existing, old
    # user account. Then they will use that old user account from then on (current user and other things will be switched around on the fly
    # in the controller).
    def merge_user!(other_user:)
      # these methods do not invoke callbacks, since not really needed for taking ownership
      CurationActivity.where(user_id: other_user.id).update_all(user_id: id)
      ResourceState.where(user_id: other_user.id).update_all(user_id: id)
      Resource.where(user_id: other_user.id).update_all(user_id: id)
      Resource.where(current_editor_id: other_user.id).update_all(current_editor_id: id)
      Role.where(user_id: other_user.id).each do |r|
        if Role.find_by(user_id: id, role_object: r.role_object)
          r.delete
        else
          r.update(user_id: id)
        end
      end

      # merge in any special things updated in other user and prefer these details from other_user over self.user
      out_hash = {}
      %i[first_name last_name email tenant_id last_login orcid].each do |i|
        out_hash[i] = other_user.send(i) unless other_user.send(i).blank?
      end
      update(out_hash)
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

    # gets the latest completed resources by user, a lot of SQL since this becomes complicated
    def latest_completed_resource_per_identifier
      # Joining on version is messy, so we just assume the latest version in a
      # group is the one with the highest resource_id.
      #
      # Note that resources with null identifiers (resources not yet assigned
      # a DOI) are assumed to be different from one another. This is a little
      # hacky, but should be OK since most of the time this will be a transient
      # state immediately after submission. However, if we reach an error state
      # before a DOI is reserved, we could end up with multiple instances of the
      # "same" resource appearing in the table.
      query = <<-SQL
        id IN
          (SELECT MAX(resources.id) AS resources_id
             FROM stash_engine_resources resources
                  JOIN stash_engine_resource_states AS states
                  ON resources.current_resource_state_id = states.id
            WHERE resources.user_id = ?
              AND states.resource_state IN ('submitted', 'processing', 'error')
         GROUP BY resources.identifier_id,
                  IF(resources.identifier_id IS NULL, resources.id, 0))
      SQL

      Resource.where(query, id)
    end

    def self.init_user_from_auth(user, auth)
      user.email = auth.info.email.split(';').first # because ucla has two values separated by ;
      # name is kludgy and many places do not provide them broken out
      user.first_name, user.last_name = split_name(auth.info.name) if auth.info.name
    end
    private_class_method :init_user_from_auth

    # convenience method for updating and returning user
    def update_user_orcid(orcid:, temp_email:)
      update(last_login: Time.new.utc, orcid: orcid)
      update(email: temp_email) if temp_email && email.nil?
      self
    end

    def self.create_user_with_orcid(auth_hash:, temp_email:)
      User.create(first_name: auth_hash[:extra][:raw_info][:first_name], last_name: auth_hash[:extra][:raw_info][:last_name],
                  email: temp_email, tenant_id: nil, last_login: Time.new.utc, orcid: auth_hash[:uid])
    end

  end

end
