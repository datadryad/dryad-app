# == Schema Information
#
# Table name: stash_engine_funders
#
#  id           :bigint           not null, primary key
#  covers_dpc   :boolean          default(TRUE)
#  covers_ldf   :string(191)
#  enabled      :boolean          default(TRUE)
#  name         :string(191)
#  payment_plan :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  ror_id       :string(191)
#
# Indexes
#
#  index_stash_engine_funders_on_ror_id  (ror_id)
#
module StashEngine
  class Funder < ApplicationRecord
    self.table_name = 'stash_engine_funders'
    belongs_to :ror_org, class_name: 'StashEngine::RorOrg', primary_key: 'ror_id', foreign_key: 'ror_id', optional: true
    has_many :roles, class_name: 'StashEngine::Role', as: :role_object, dependent: :destroy
    has_many :users, through: :roles

    enum :payment_plan, { tiered: 0, '2025': 1 }

    scope :exemptions, -> { where(enabled: true, covers_dpc: true) }
  end
end
