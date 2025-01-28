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
    enum :flag, { priority: 0 }

    belongs_to :flaggable, polymorphic: true, optional: true
    

  end
end
