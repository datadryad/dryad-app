# == Schema Information
#
# Table name: stash_engine_flags
#
#  id             :bigint           not null, primary key
#  flag           :integer
#  flaggable_type :string(191)
#  note           :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  flaggable_id   :string(191)
#
# Indexes
#
#  index_stash_engine_flags_on_flaggable_type_and_flaggable_id  (flaggable_type,flaggable_id)
#
module StashEngine
  class Flag < ApplicationRecord
    self.table_name = 'stash_engine_flags'
    has_paper_trail
    enum :flag, { priority: 0, pending_action: 1, sensitive_data: 2, careful_attention: 3, technical_glitch: 4, research_integrity: 5 }

    belongs_to :flaggable, polymorphic: true, optional: true

    belongs_to :user, -> { where(flag: { flaggable_type: 'StashEngine::User' }).includes(:flag) }, foreign_key: 'flaggable_id', optional: true
    belongs_to :tenant, -> { where(flag: { flaggable_type: 'StashEngine::Tenant' }).includes(:flag) }, foreign_key: 'flaggable_id', optional: true
    belongs_to :journal, -> { where(flag: { flaggable_type: 'StashEngine::Journal' }).includes(:flag) }, foreign_key: 'flaggable_id', optional: true
    belongs_to :resource, -> { where(flag: { flaggable_type: 'StashEngine::Resource' }).includes(:flag) }, foreign_key: 'flaggable_id', optional: true
  end
end
