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
require "test_helper"

class ExternalIntegrationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
