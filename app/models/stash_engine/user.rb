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
  class User < ApplicationRecord
    include StashEngine::Support::UserRoles
    self.table_name = 'stash_engine_users'
    has_many :roles, dependent: :destroy
    has_many :resources, through: :roles, source: :role_object, source_type: 'StashEngine::Resource'
    has_many :journals, through: :roles, source: :role_object, source_type: 'StashEngine::Journal'
    has_many :journal_organizations, through: :roles, source: :role_object, source_type: 'StashEngine::JournalOrganization'
    has_many :funders, through: :roles, source: :role_object, source_type: 'StashEngine::Funder'
    has_many :tenants, through: :roles, source: :role_object, source_type: 'StashEngine::Tenant'
    belongs_to :affiliation, class_name: 'StashDatacite::Affiliation', optional: true
    belongs_to :tenant, class_name: 'StashEngine::Tenant', optional: true
    has_many :admin_searches, class_name: 'StashEngine::AdminSearch', dependent: :destroy
    has_one :flag, class_name: 'StashEngine::Flag', as: :flaggable, dependent: :destroy
    has_one :email_token, class_name: 'StashEngine::EmailToken', dependent: :destroy
    has_one :api_application,
            class_name: 'Doorkeeper::Application',
            foreign_key: :owner_id,
            dependent: :destroy
    has_many :access_tokens, through: :api_application, class_name: 'Doorkeeper::AccessToken'

    accepts_nested_attributes_for :roles, :flag

    validates :email, format: { with: EMAIL_REGEX, message: '%{value} is not a valid email address' }, allow_blank: true

    def self.system_user
      find(0)
    end

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

    def orcid_link
      return "https://sandbox.orcid.org/#{orcid}" if APP_CONFIG.orcid.site == 'https://sandbox.orcid.org/'

      "https://orcid.org/#{orcid}"
    end

    def name
      "#{first_name} #{last_name}".strip
    end

    def name_last_first
      [last_name, first_name].join(', ')
    end

    def proxy_user? = false

    def journals_as_admin
      admin_org_journals = journal_organizations.map(&:journals_sponsored_deep).flatten
      journals | admin_org_journals
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
        if Role.find_by(user_id: id, role_object: r.role_object, role: r.role)
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
