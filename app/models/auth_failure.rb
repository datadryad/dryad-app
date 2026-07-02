# == Schema Information
#
# Table name: auth_failures
#
#  id         :bigint           not null, primary key
#  error_type :string(191)
#  ip         :string(191)
#  params     :json
#  url        :text(65535)
#  user_agent :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
class AuthFailure < ApplicationRecord
  enum :error_type, %w[unauthorized api_unauthorized api_expired_token].index_by(&:to_sym)

  belongs_to :user, class_name: 'StashEngine::User', optional: true
end
