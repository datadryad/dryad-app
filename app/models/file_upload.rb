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
class FileUpload < ApplicationRecord
  belongs_to :file, class_name: 'StashEngine::GenericFile'

  enum :status, %w[pending complete aborted].index_by(&:to_sym)
end
