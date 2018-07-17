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

    def self.partner_list
      all.delete_if { |t| t.partner_display == false }
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

    def data_deposit_agreement?
      dda = File.join(Rails.root, 'app', 'views', 'tenants', tenant_id, '_dda.html.erb')
      File.exist?(dda) && data_deposit_agreement
    end

    def omniauth_login_path(params = nil)
      @omniauth_login_path ||= send("#{authentication.strategy}_login_path".intern, params)
    end

    # generate login path for shibboleth & omniauth, this is unusual since we have multi-institution login,
    # so have to hack around limitations in the normal omniauth/shibboleth by directly addressing
    # shibboleth.sso
    def shibboleth_login_path(params = nil)
      extra_params = (params ? "?#{params.to_param}" : '')
      "https://#{full_domain}/Shibboleth.sso/Login?" \
          "target=#{CGI.escape("#{callback_path_begin}shibboleth/callback#{extra_params}")}" \
          "&entityID=#{CGI.escape(authentication.entity_id)}&tenant_id=#{CGI.escape(tenant_id)}"
    end

    def google_login_path(params = nil)
      # note that StashEngine.app.stash_mount includes a leading slash
      # you must add extra params in state param https://stackoverflow.com/questions/7722062/google-oauth2-redirect-uri-with-several-parameters
      state_param_val = CGI.escape((params ? params.to_param : ''))
      qs = (state_param_val.blank? ? '' : "?state=#{state_param_val}")
      path = "#{callback_path_begin}google_oauth2#{qs}"
      return path unless full_domain =~ /^localhost(:[0-9]+)?$/
      path.sub('https', 'http') # HACK: for testing
    end

    def callback_path_begin
      "https://#{full_domain}#{StashEngine.app.stash_mount}/auth/"
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
      StashEngine.tenants.each_value do |v|
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
      return nil unless StashEngine.tenants[tenant_id]
      new(StashEngine.tenants[tenant_id])
    end

    def full_url(path)
      URI::HTTPS.build(host: full_domain, path: path).to_s
    end

  end
end
