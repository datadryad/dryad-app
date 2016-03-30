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
  end
end
