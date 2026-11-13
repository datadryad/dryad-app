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
# Indexes
#
#  idx_on_integrator_id_integrator_type_0f5a01e1d7  (integrator_id,integrator_type)
#
FactoryBot.define do
  factory :external_integration do
    integration { 'scholarone' }
    integrator_id { 1 }
    integrator_type { 'MyString' }
    username { 'MyString' }
    password { 'MyString' }
    details { { site_name: 'MyString' } }
  end
end
