module StashEngine
  class User < ActiveRecord::Base
    has_many :resources

    def self.from_omniauth_orcid(auth_hash:, emails:)
      users = find_by_orcid_or_emails(orcid: auth_hash[:uid], emails: emails)
      raise 'More than one user matches the ID or email returned by ORCID' if users.count > 1

      return users.first.update_user_orcid(orcid: auth_hash[:uid]) if users.count == 1

      create_user_with_orcid(auth_hash: auth_hash, email: emails.try(:first))
    end

    def self.find_by_orcid_or_emails(orcid:, emails:)
      emails = Array.wrap(emails)
      emails = emails.delete_if(&:blank?)
      User.where(['orcid = ? or email IN ( ? )', orcid, emails])
    end

    def name
      "#{first_name} #{last_name}".strip
    end

    def superuser?
      role == 'superuser'
    end

    def self.split_name(name)
      first = name.split(' ').first
      last = ''
      last = name.split(' ').last unless name.split(' ').last == first
      [first, last]
    end

    def tenant
      Tenant.find(tenant_id)
    end

    # gets the latest completed resources by user, a lot of SQL since this becomes complicated
    def latest_completed_resource_per_identifier # rubocop:disable Metrics/MethodLength
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
              AND states.resource_state IN ('submitted', 'processing')
         GROUP BY resources.identifier_id,
                  IF(resources.identifier_id IS NULL, resources.id, 0))
      SQL

      Resource.where(query, id)
    end

    def self.init_user_from_auth(user, auth)
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email.split(';').first # because ucla has two values separated by ;
      # name is kludgy and many places do not provide them broken out
      user.first_name, user.last_name = split_name(auth.info.name) if auth.info.name
      user.oauth_token = auth.credentials.token
    end
    private_class_method :init_user_from_auth

    # convenience method for updating and returning user
    def update_user_orcid(orcid:)
      update(last_login: Time.new, orcid: orcid)
      self
    end

    def self.create_user_with_orcid(auth_hash:, email:)
      # TODO: we need to remove the ucop default for tenant_id and instead nil and then prompt for institution (or dryad) before continuing
      User.create(first_name: auth_hash[:extra][:raw_info][:first_name], last_name: auth_hash[:extra][:raw_info][:last_name],
                  email: email, tenant_id: 'ucop', last_login: Time.new, role: 'user', orcid: auth_hash[:uid])
    end
  end
end
