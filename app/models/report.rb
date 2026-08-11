# == Schema Information
#
# Table name: reports
#
#  id          :bigint           not null, primary key
#  bucket      :string(191)
#  report_type :string(191)
#  s3_key      :string(191)
#  status      :string(191)
#  time        :datetime
#  title       :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Report < ApplicationRecord

  enum(:report_type, %w[age_by_status].to_h { |i| [i.to_sym, i] })

  def download_url
    s3 = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG.s3.reports_bucket)
    s3.presigned_download_url(s3_key: s3_key)
  end
end
