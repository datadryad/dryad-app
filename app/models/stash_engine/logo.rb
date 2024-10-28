# == Schema Information
#
# Table name: stash_engine_logos
#
#  id         :bigint           not null, primary key
#  data       :text(4294967295)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module StashEngine
  class Logo < ApplicationRecord
    self.table_name = 'stash_engine_logos'
    has_one :tenant, class_name: 'StashEngine::Tenant', dependent: :destroy
  end
end
