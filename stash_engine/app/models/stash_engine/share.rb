require 'securerandom'

module StashEngine
  class Share < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    before_create :generate_secret_id

    def tenant
      resource.tenant
    end

    def sharing_link
      return nil unless tenant
      StashEngine::Engine.routes.url_helpers.share_url(protocol: 'https', id: secret_id)
    end

    def generate_secret_id
      #::urlsafe_base64 generates a random URL-safe base64 string.
      # The result may contain A-Z, a-z, 0-9, “-” and “_”.
      self.secret_id = SecureRandom.urlsafe_base64(32)
    end
  end
end
