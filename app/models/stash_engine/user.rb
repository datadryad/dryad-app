module StashEngine
  class User < ActiveRecord::Base

    def self.from_omniauth(auth, tenant_abbrev)

      where(uid: auth[:uid]).first_or_initialize.tap do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email.split(";").first #because ucla has two values separated by ;

        # name is kludgy and many places do not provide them broken out
        if user.name
          name = user.name
          user.first_name = name.split(' ').first
          user.last_name = name.split(' ').last unless name.split(' ').last == user.first_name
        end
        #user.first_name = auth.info.first_name
        #user.last_name = auth.info.last_name
        #if user.provider == "shibboleth"
        #  user.external_id = auth.info.external_id
        #else
        #  user.external_id = auth.info.email
        #end
        user.oauth_token = auth.credentials.token
        user.tenant_abbrev = tenant_abbrev
        user.save!
      end
    end

  end
end
