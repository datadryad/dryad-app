module StashEngine
  class User < ActiveRecord::Base
    has_many :resources

    def self.from_omniauth(auth, tenant_id, orcid)
      where(uid: auth[:uid]).first_or_initialize.tap do |user|
        init_user_from_auth(user, auth)
        user.tenant_id = tenant_id
        user.last_login = Time.new
        user.orcid = orcid unless orcid.blank?
        user.save!
      end
    end

    def name
      "#{first_name} #{last_name}".strip
    end

    def superuser?
      role == 'superuser'
    end

    def self.split_name(name)
      comma_split = name.split(',')
      return [comma_split[1].strip, comma_split[0].strip] if comma_split.length == 2 # gets a reversed name with comma like "Janee, Greg"
      first = (name.split(' ').first || '').strip
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
  end
end
