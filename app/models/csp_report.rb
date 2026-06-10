# == Schema Information
#
# Table name: csp_reports
#
#  id          :bigint           not null, primary key
#  blocked_uri :text(65535)
#  directive   :string(191)
#  ip          :string(191)
#  report      :json
#  status_code :string(191)
#  url         :text(65535)
#  user_agent  :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class CspReport < ApplicationRecord
end
