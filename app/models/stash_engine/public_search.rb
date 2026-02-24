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

    scope :subscribed, -> { where.not(emailed_at: nil) }

    def email_updates
      now = Time.now.utc
      return if now < emailed_at

      fields = 'dc_identifier_s dc_title_s dc_creator_sm dc_description_s dct_issued_dt'
      service = StashApi::SolrSearchService.new(
        query: properties[:q],
        filters: properties.except(:q, :id).stringify_keys.merge(
          'sort' => 'date desc', 'publishedSince' => emailed_at.utc.iso8601
        )
      )
      result = service.search(page: 1, per_page: 10, fields: fields, facet: true, wt: :json)
      update(emailed_at: now)
      results = result['response']
      return if results['numFound'].zero?

      results
    end

  end
end
