require 'securerandom'

module StashEngine
  class Share < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    before_create :generate_sharing_link

    def user_tenant
      resource = Resource.find(self.resource_id)
      user_tenant = resource.user.tenant
    end

    def generate_sharing_link
      tenant = user_tenant.full_domain
      random_string = SecureRandom.base64(32)
      template = "https://#{tenant}/stash/share/#{random_string}"
      self.sharing_link = template
      self.expiration_date = user_tenant.sharing_expiration_days.days.from_now
    end
  end
end
