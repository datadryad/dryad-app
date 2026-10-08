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

RSpec.describe ExternalIntegration, type: :model do

  describe 'associations' do
    it { is_expected.to belong_to(:integrator) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:integration) }
    it { is_expected.to validate_presence_of(:integrator_id) }
    it { is_expected.to validate_presence_of(:integrator_type) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:password) }
  end
end
