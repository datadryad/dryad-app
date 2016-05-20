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

    #gets the latest completed resources by user, a lot of SQL since this becomes complicated
    def latest_completed_resource_per_identifier
      # SELECT resources.*, MAX(versions.version) as max_version FROM `stash_engine_resources` resources
      # JOIN `stash_engine_versions` versions
      # ON resources.`id` = versions.resource_id
      # JOIN `stash_engine_resource_states` states
      # ON resources.current_resource_state_id = states.id
      # WHERE identifier_id IS NOT NULL AND states.resource_state IN ('submitted')
      # AND resources.user_id = 7
      # GROUP BY identifier_id
      # ORDER BY updated_at DESC;"

      Resource.select("stash_engine_resources.*, MAX(stash_engine_versions.version)").joins(:version).submitted.
          where('identifier_id IS NOT NULL').where(user_id: id).
          group(:identifier_id).order(:updated_at)
    end
  end
end
