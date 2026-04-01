# == Schema Information
#
# Table name: data_review_logs
#
#  id          :bigint           not null, primary key
#  deleted_at  :datetime
#  note        :string(191)
#  status      :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  journal_id  :integer
#  resource_id :integer
#  user_id     :integer
#
# Indexes
#
#  index_data_review_logs_on_deleted_at          (deleted_at)
#  index_data_review_logs_on_resource_id_and_id  (resource_id,id)
#
class DataReviewLog < ApplicationRecord
  self.table_name = :data_review_logs

  belongs_to :resource, class_name: 'StashEngine::Resource'
  belongs_to :user, class_name: 'StashEngine::User'
  belongs_to :journal, class_name: 'StashEngine::Journal'
end
