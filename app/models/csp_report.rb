# == Schema Information
#
# Table name: csp_reports
#
#  id          :bigint           not null, primary key
#  blocked_uri :string(191)
#  directive   :string(191)
#  ip          :string(191)
#  report      :json
#  status_code :string(191)
#  url         :string(191)
#  user_agent  :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class CspReport < ApplicationRecord
end
