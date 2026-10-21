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
require "test_helper"

class FileUploadTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
