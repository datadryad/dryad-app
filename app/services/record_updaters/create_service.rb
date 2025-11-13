module RecordUpdaters
  class CreateService

    def create_from_award_matching(contributor)
      keys = %i[award_number award_uri award_title name_identifier_id contributor_name]
      new_info = AwardMetadataService.new(contributor).award_details(full_info: true)
      return if new_info.blank?

      existing_info = contributor.attributes.symbolize_keys.slice(*keys)
      return unless new_info != existing_info

      record = RecordUpdater.find_or_initialize_by(
        record: contributor,
        data_type: :funder,
        status: RecordUpdater.statuses[:pending]
      )
      record.update(update_data: new_info.to_json)
    end
  end
end
