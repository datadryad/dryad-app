# == Schema Information
#
# Table name: external_integrations
#
#  id              :bigint           not null, primary key
#  details         :json
#  integration     :string(191)
#  integrator_type :string(191)
#  password        :string(191)
#  username        :string(191)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  integrator_id   :integer
#
class ExternalIntegration < ApplicationRecord
  encrypts :username
  encrypts :password

  enum :integration, %w[scholarone].index_by(&:to_sym)

  belongs_to :integrator, polymorphic: true

  validates_presence_of :integration, :integrator_id, :integrator_type, :username, :password
end
