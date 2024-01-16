# == Schema Information
#
# Table name: stash_engine_funder_roles
#
#  id          :bigint           not null, primary key
#  user_id     :bigint
#  funder_id   :string(191)
#  funder_name :string(191)
#  role        :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashEngine
  class FunderRole < ApplicationRecord
    self.table_name = 'stash_engine_funder_roles'
    belongs_to :user

    scope :admins, -> { where(role: 'admin') }
  end
end
