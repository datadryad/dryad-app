# == Schema Information
#
# Table name: sponsor_invoices
#
#  id           :bigint           not null, primary key
#  s3_key       :string(191)
#  sponsor_type :string(191)
#  year         :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  sponsor_id   :integer
#
# Indexes
#
#  index_sponsor_invoices_on_sponsor_id_and_sponsor_type  (sponsor_id,sponsor_type)
#
FactoryBot.define do
  factory :sponsor_invoice do
    sponsor_id { 1 }
    sponsor_type { 'MyString' }
    year { 1 }
    path { 'MyString' }
  end
end
