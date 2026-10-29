# == Schema Information
#
# Table name: downloads
#
#  id          :bigint           not null, primary key
#  as_zip      :boolean
#  from_api    :boolean
#  ip          :string(191)
#  user_agent  :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  file_id     :integer
#  resource_id :integer
#  user_id     :integer
#
FactoryBot.define do
  factory :download do
    resource_id { 1 }
    file_id { 1 }
    from_api { false }
    as_zip { false }
    ip { 'MyString' }
    user_id { 1 }
  end
end
