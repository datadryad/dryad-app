# == Schema Information
#
# Table name: record_updaters
#
#  id          :bigint           not null, primary key
#  data_type   :string(191)
#  record_type :string(191)
#  status      :integer          default("pending")
#  update_data :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :integer
#  user_id     :integer
#
# Indexes
#
#  index_record_updaters_on_data_type                  (data_type)
#  index_record_updaters_on_record_type_and_record_id  (record_type,record_id)
#  index_record_updaters_on_status                     (status)
#
class RecordUpdater < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :user, class_name: 'StashEngine::User', optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }
  enum :data_type, { funder: :funder }

  def resource
    record.resource
  end
end
