require 'securerandom'

module StashEngine
  class Share < ApplicationRecord
    self.table_name = 'stash_engine_shares'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'

    before_create :generate_secret_id

    def sharing_link
      Rails.application.routes.url_helpers.share_url(protocol: 'https', id: secret_id)
    end

    def generate_secret_id
      # ::urlsafe_base64 generates a random URL-safe base64 string.
      # The result may contain A-Z, a-z, 0-9, “-” and “_”.
      self.secret_id = SecureRandom.urlsafe_base64(32)
    end
  end
end
