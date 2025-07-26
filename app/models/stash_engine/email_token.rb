# == Schema Information
#
# Table name: stash_engine_email_tokens
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  token      :string(191)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :string(191)
#  user_id    :integer
#
require 'securerandom'

module StashEngine
  class EmailToken < ApplicationRecord
    self.table_name = 'stash_engine_email_tokens'
    belongs_to :user, class_name: 'StashEngine::User'
    belongs_to :tenant, class_name: 'StashEngine::Tenant', optional: true

    after_create :create_token

    def send_token
      if tenant.present?
        StashEngine::UserMailer.check_tenant_email(self).deliver_now
      else
        StashEngine::UserMailer.check_email(self).deliver_now
      end
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
