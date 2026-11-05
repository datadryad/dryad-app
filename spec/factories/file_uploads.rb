# == Schema Information
#
# Table name: file_uploads
#
#  id          :bigint           not null, primary key
#  key         :string(191)
#  part_number :integer
#  size        :bigint
#  status      :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  file_id     :integer
#  resource_id :integer
#  upload_id   :string(191)
#  user_id     :integer
#
FactoryBot.define do
  factory :file_upload do
    user_id { 1 }
    key { 'MyString' }
    upload_id { 'MyString' }
    file_id { 'MyString' }
    resource_id { 'MyString' }
    status { 'pending' }
    part_number { 1 }
    size { '' }
  end
end
