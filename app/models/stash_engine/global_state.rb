# == Schema Information
#
# Table name: stash_engine_global_states
#
#  id         :bigint           not null, primary key
#  key        :string(191)
#  state      :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module StashEngine
  class GlobalState < ApplicationRecord
    self.table_name = 'stash_engine_global_states'

  end
end
