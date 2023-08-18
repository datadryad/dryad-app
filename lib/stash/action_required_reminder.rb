module Stash
  module ActionRequiredReminder
    # rubocop:disable Metrics/AbcSize
    def self.find_action_required_items
      # map down to info item about action_required items
      # all_ids = StashEngine::Identifier.all

      # the query is complicated but only select items with a terminal curation status of action_required or in_progress
      # to reduce the manual sifting through of curation statuses that will not be relevant
      subquery = <<-SQL
        (SELECT resource_id, MAX(id) AS max_id FROM stash_engine_curation_activities GROUP BY resource_id) AS latest_activities
      SQL
      all_ids = StashEngine::Identifier.joins(latest_resource: :curation_activities)
        .joins("INNER JOIN #{subquery} ON stash_engine_curation_activities.id = latest_activities.max_id")
        .where("stash_engine_curation_activities.status IN ('in_progress', 'action_required')")
        .where('stash_engine_identifiers.created_at > ?', 1.year.ago)
        .distinct
      all_ids.map.with_index do |identifier, idx|
        puts "Checking identifier #{idx + 1}/#{all_ids.length} for action_required status" if (idx + 1) % 100 == 0

        # gets all activities for identifier
        activities = StashEngine::CurationActivity.where(resource_id: identifier.resources.map(&:id)).order(:created_at)

        # it can only be action required if it's the last status or it was the last status before in_progress
        next(nil) if activities.empty? || !%w[action_required in_progress].include?(activities.last.status)

        next(nil) if activities.last.status == 'in_progress' && activities[-2]&.status != 'action_required'

        # separate the last contiguous block of action_required activities from the rest of them
        relevant_activities = last_block(activities: activities)

        # it's action_required so try to calculate what's required to understand status set and previous notifications
        set_at = relevant_activities.first&.updated_at

        reminder_1 = relevant_activities.select { |a| a.note&.include?('action required reminder 1') }&.first&.updated_at
        reminder_2 = relevant_activities.select { |a| a.note&.include?('action required reminder 2') }&.first&.updated_at

        { set_at: set_at, reminder_1: reminder_1, reminder_2: reminder_2, identifier: identifier }
      end.compact
    end
    # rubocop:enable Metrics/AbcSize

    def self.last_block(activities:)
      relevant_activities = []

      # go from newest to oldest to find when this block of action_required activities started
      activities.reverse.each do |activity|
        next if activity.status == 'in_progress'

        break if activity.status != 'action_required' # we are no longer in this block of contiguous action_required activities

        relevant_activities << activity
      end

      # return them back in normal order: oldest to newest
      relevant_activities.reverse
    end
  end
end
