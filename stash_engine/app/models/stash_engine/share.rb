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
      StashEngine::Engine.routes.url_helpers.share_url(host: tenant.full_domain, protocol: 'https', id: secret_id)
      # URI::HTTPS.build(host: tenant.full_domain, path: "/stash/share/#{ERB::Util.url_encode(secret_id)}").to_s
    end

    def generate_secret_id
      #::urlsafe_base64 generates a random URL-safe base64 string.
      # The result may contain A-Z, a-z, 0-9, “-” and “_”.
      self.secret_id = SecureRandom.urlsafe_base64(32)
    end
  end
end
