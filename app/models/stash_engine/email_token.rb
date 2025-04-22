# == Schema Information
#
# Table name: stash_engine_email_tokens
#
#  id         :bigint           not null, primary key
#  tenant_id     :string(191)
#  user_id     :integer
#  token      :string(191)
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'securerandom'

module StashEngine
  class EmailToken < ApplicationRecord
    self.table_name = 'stash_engine_email_tokens'
    belongs_to :user, class_name: 'StashEngine::User'
    belongs_to :tenant, class_name: 'StashEngine::Tenant'

    after_create :create_token

    def send_token
      StashEngine::UserMailer.check_tenant_email(self).deliver_now
    end

    def expired?
      Time.new > expires_at
    end

    private

    def create_token
      update(token: SecureRandom.alphanumeric(6).upcase, expires_at: Time.new + 15.minutes)
    end
  end
end
