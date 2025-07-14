# == Schema Information
#
# Table name: action_required_reports
#
#  id          :bigint           not null, primary key
#  report      :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#  user_id     :integer
#
class ActionRequiredReport < ApplicationRecord
  belongs_to :resource, class_name: 'StashEngine::Resource'
  belongs_to :user, class_name: 'StashEngine::User'

  def report
    JSON.parse(super) if super.present?
  end
end
