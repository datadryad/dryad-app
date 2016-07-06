module StashEngine
  class User < ActiveRecord::Base
    has_many :resources
    def self.from_omniauth(auth, tenant_id)
      where(uid: auth[:uid]).first_or_initialize.tap do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email.split(';').first #because ucla has two values separated by ;
        # name is kludgy and many places do not provide them broken out
        user.first_name, user.last_name = split_name(auth.info.name) if auth.info.name
        user.oauth_token = auth.credentials.token
        user.tenant_id = tenant_id
        user.save!
      end
    end

    def self.split_name(name)
      first = name.split(' ').first
      last = ''
      last = name.split(' ').last unless name.split(' ').last == first
      [first, last]
    end

    def tenant
      Tenant.find(self.tenant_id)
    end

    #gets the latest completed resources by user, a lot of SQL since this becomes complicated
    def latest_completed_resource_per_identifier
      # this is hackish since it requires resource ids to be assigned in ascending order,
      # so the last version in a group is also the highest resource_id.
      # however, the join to version becomes more complicated and unoptimized since a group and Max doesn't work across
      # different tables and returns a max that is independent from the correct ID.
      #
      # for optimization we may need to add a marker for the latest completed resource to the table in the future
      # and then toggle it on (and previous versions off) in our code when something is submitted.

      # Resource.find_by_sql(["
      #   SELECT * FROM stash_engine_resources
      #   WHERE id IN
      #   (SELECT MAX(resources.id) as resources_id FROM `stash_engine_resources` resources
      #   JOIN `stash_engine_resource_states` states
      #   ON resources.current_resource_state_id = states.id
      #   WHERE resources.user_id = ? AND resources.identifier_id IS NOT NULL
      #   AND states.resource_state IN ('submitted')
      #   GROUP BY resources.identifier_id)", id])

      Resource.where("id IN
        (SELECT MAX(resources.id) as resources_id FROM `stash_engine_resources` resources
        JOIN `stash_engine_resource_states` states
        ON resources.current_resource_state_id = states.id
        WHERE resources.user_id = ? AND resources.identifier_id IS NOT NULL
        AND states.resource_state IN ('submitted')
        GROUP BY resources.identifier_id)", id)

      # this doesn't work correctly
      # Resource.select("stash_engine_resources.*, MAX(stash_engine_versions.version)").joins(:version).submitted.
      #    where('identifier_id IS NOT NULL').where(user_id: id).
      #    group(:identifier_id).order(:updated_at)

      # /* I thought it worked, but it doesn't */
      # SELECT resources.*, MAX(versions.version) as max_version FROM `stash_engine_resources` resources
      # JOIN `stash_engine_versions` versions
      # ON resources.`id` = versions.resource_id
      # JOIN `stash_engine_resource_states` states
      # ON resources.current_resource_state_id = states.id
      # WHERE identifier_id IS NOT NULL AND states.resource_state IN ('submitted')
      # AND resources.user_id = 7
      # GROUP BY identifier_id
      # ORDER BY updated_at DESC;
    end
  end
end
