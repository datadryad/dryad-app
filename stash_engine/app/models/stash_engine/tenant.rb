require 'ostruct'
module StashEngine
  class Tenant

    # TODO: Don't assume existince of UCOP logo
    DEFAULT_LOGO_FILE = 'logo_ucop.svg'.freeze

    # This was originally designed differently and I had to change it to create some instances on the fly because
    # testing loads things twice and didn't work correctly to create instances up front on engine initialization
    # in the test environment.  :-(

    def initialize(hash)
      @ostruct = hash.to_ostruct
    end

    # return list of all tenants, tenant is a lightly wrapped ostruct (see method missing) with extra methods in here
    def self.all
      StashEngine.tenants.values.map { |h| new(h) if h['enabled'] && h['enabled'] == true }.compact.sort_by(&:short_name)
    end

    # gets the Tenant class to respond to the keys so you can call hash like methods
    def method_missing(m) # rubocop:disable Style/MethodMissing
      @ostruct.send(m)
    end

    def logo_file
      @logo_file ||= begin
        tenant_images_path = File.join(Rails.root, 'app', 'assets', 'images', 'tenants')
        logo_filenames = %w[svg png jpg].lazy.map { |ext| "logo_#{tenant_id}.#{ext}" }
        logo_filenames.find do |filename|
          image_file = File.join(tenant_images_path, filename)
          File.exist?(image_file)
        end || DEFAULT_LOGO_FILE
      end
    end

    def omniauth_login_path
      @omniauth_login_path ||= send("#{authentication.strategy}_login_path".intern)
    end

    # generate login path for shibboleth & omniauth, this is unusual since we have multi-institution login, so have to
    # hack around limitations in the normal omniauth/shibboleth by directly addressing shibboleth.sso
    def shibboleth_login_path
      # "/stash/auth/shibboleth?entityid=#{CGI.escape(authentication.entity_id)}"

      # I think the following is incorrect and we should go to the domain for each host directly
      # "https://#{StashEngine.app.shib_sp_host}/Shibboleth.sso/Login?" \
      #    "target=#{CGI.escape("https://#{StashEngine.app.shib_sp_host}" \
      #    "#{StashEngine.app.stash_mount}/auth/shibboleth/callback")}" \
      #    "&entityID=#{CGI.escape(authentication.entity_id)}"

      "https://#{full_domain}/Shibboleth.sso/Login?" \
          "target=#{CGI.escape("https://#{full_domain}" \
          "#{StashEngine.app.stash_mount}/auth/shibboleth/callback")}" \
          "&entityID=#{CGI.escape(authentication.entity_id)}"
    end

    def google_login_path
      # note that StashEngine.app.stash_mount includes a leading slash
      path = "https://#{full_domain}#{StashEngine.app.stash_mount}/auth/google_oauth2"
      return path unless tenant_id == 'localhost'
      path.sub('https', 'http') # HACK: for testing
    end

    def sword_params
      repository = self.repository
      {
        collection_uri: repository.endpoint,
        username: repository.username,
        password: repository.password
      }
    end

    def self.by_domain(domain)
      i = by_domain_w_nil(domain)
      return all.first if i.nil?
      i
    end

    def self.by_domain_w_nil(domain)
      StashEngine.tenants.values.each do |v|
        if v['enabled'] && v['enabled'] == true
          return new(v) if Regexp.new(v['domain_regex']).match(domain)
        end
      end
      nil
    end

    def self.exists?(tenant_id)
      StashEngine.tenants.key?(tenant_id)
    end

    def self.find(tenant_id)
      new(StashEngine.tenants[tenant_id])
    end

    def landing_url(path_to_landing)
      URI::HTTPS.build(host: full_domain, path: path_to_landing).to_s
    end
  end
end
