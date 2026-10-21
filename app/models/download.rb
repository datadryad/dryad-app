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
class Download < ApplicationRecord
end
