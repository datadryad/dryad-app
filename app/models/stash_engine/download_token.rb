# == Schema Information
#
# Table name: stash_engine_download_tokens
#
#  id          :integer          not null, primary key
#  available   :datetime
#  token       :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_stash_engine_download_tokens_on_token  (token)
#
module StashEngine
  class DownloadToken < ApplicationRecord
    self.table_name = 'stash_engine_download_tokens'
    belongs_to :resource, class_name: 'StashEngine::Resource'

    def availability_delay_seconds
      return 0 if available.nil?
      return 60 if (available - Time.new) < 0 # it was already supposed to be available, so who knows how long, lets guess 60 seconds

      (available - Time.new).ceil
    end
  end
end
