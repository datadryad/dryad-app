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
class SponsorInvoice < ApplicationRecord
  belongs_to :sponsor, polymorphic: true

  def download_url
    s3 = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG.s3.invoices_bucket)
    s3.presigned_download_url(s3_key: s3_key)
  end
end
