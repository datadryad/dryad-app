# == Schema Information
#
# Table name: stash_engine_saved_searches
#
#  id          :bigint           not null, primary key
#  default     :boolean
#  description :string(191)
#  emailed_at  :datetime
#  properties  :json
#  share_code  :string(191)
#  title       :string(191)
#  type        :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#
# Indexes
#
#  index_stash_engine_saved_searches_on_user_id_and_type  (user_id,type)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => stash_engine_users.id)
#
module StashEngine
  class PublicSearch < SavedSearch
  end
end
