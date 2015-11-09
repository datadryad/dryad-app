require 'ostruct'
module StashEngine
  class Tenant

    def self.tenants=(tenants)
      @@tenants = {}
      tenants.each do |k,v|
        @@tenants[k] = self.new(v)
      end
    end

    def initialize(hash)
      @ostruct = hash.to_ostruct
    end

    # return list of all tenants, tenant is a lightly wrapped ostruct (see method missing) with extra methods in here
    def self.all
      @@tenants.values
    end

    #gets the Tenant class to respond to the keys so you can call hash like methods
    def method_missing(m, *args, &block)
      @ostruct.send(m)
    end

    def omniauth_login_path
      send("#{authentication.strategy}_login_path".intern)
    end

    # generate login path for shibboleth & omniauth, this is unusual since we have multi-institution login, so have to
    # hack around limitations in the normal omniauth/shibboleth by directly addressing shibboleth.sso
    def shibboleth_login_path
      #"/stash/auth/shibboleth?entityid=#{CGI.escape(authentication.entity_id)}"
      "https://#{StashEngine.app.shib_sp_host}/Shibboleth.sso/Login?" +
          "target=#{CGI.escape("https://#{StashEngine.app.shib_sp_host}#{StashEngine.app.stash_mount}/auth/shibboleth/callback")}" +
          "&entityID=#{CGI.escape(authentication.entity_id)}"
    end

    def google_login_path
      "#{StashEngine.app.stash_mount}/auth/google_oauth2"
    end

    def self.by_domain(domain)
      @@tenants.values.each do |t|
        return t if Regexp.new(t.domain_regex).match(domain)
      end
    end

    def self.find(tenant_id)
      @@tenants[tenant_id]
    end

  end
end
