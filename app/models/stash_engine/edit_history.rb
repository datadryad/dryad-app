# == Schema Information
#
# Table name: stash_engine_edit_histories
#
#  id           :integer          not null, primary key
#  resource_id  :integer
#  user_comment :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
module StashEngine
  class EditHistory < ApplicationRecord
    self.table_name = 'stash_engine_edit_histories'
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'

    amoeba do
      disable
    end
  end
end
