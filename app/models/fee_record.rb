# == Schema Information
#
# Table name: fee_records
#
#  id          :bigint           not null, primary key
#  deleted_at  :datetime
#  fees        :json
#  status      :integer          default("invoice")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :bigint
#
class FeeRecord < ApplicationRecord
  acts_as_paranoid

  belongs_to :resource, class_name: 'StashEngine::Resource'

  enum :status, { invoice: 0, receipt: 1 }

  def fees
    JSON.parse(super, symbolize_names: true)
  end
end
