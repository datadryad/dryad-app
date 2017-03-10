require 'securerandom'

module StashEngine
  class Share < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    before_create :generate_secret_id

    def tenant
      resource.try(:tenant)
    end

    def sharing_link
      return nil unless tenant
      URI::HTTPS.build(host: tenant.full_domain, path: "/stash/share/#{secret_id}").to_s
    end

    #def generate_sharing_link
    #  tenant = user_tenant.full_domain
    #  random_string = SecureRandom.base64(32)
    #  template = "https://#{tenant}/stash/share/#{random_string}"
    #  self.sharing_link = template
    #  self.expiration_date = user_tenant.sharing_expiration_days.days.from_now
    #end

    def generate_secret_id
      self.secret_id = SecureRandom.base64(32)
      self.expiration_date = tenant.sharing_expiration_days.days.from_now
    end
  end
end
