module StashEngine
  class DatasetRemindersService < StashEngine::RemindersBaseService

    # Send In Progress delete email notification
    # - email is sent monthly starting from first month until 1 year
    # - after 1 year the resource should get deleted
    def send_in_progress_reminders_by_day(days_number)
      log "Mailing users whose datasets have been in_progress since #{days_number.days.ago}"
      StashEngine::Resource.joins(:current_resource_state)
        .where("stash_engine_resource_states.resource_state = 'in_progress'")
        .where('stash_engine_resources.updated_at <= ?', days_number.days.ago)
        .each do |r|

        reminder_flag = "#{days_number} days in_progress_reminder CRON"
        if r.curation_activities.where('note LIKE ?', "%#{reminder_flag}%").empty?
          log_data_for_status('in_progress', resource)
          StashEngine::UserMailer.in_progress_reminder(r).deliver_now
          create_activity(reminder_flag, r)
        end
      rescue StandardError => e
        log "    Exception! #{e.message}"
      end
    end

    def action_required_reminder
      items = Stash::ActionRequiredReminder.find_action_required_items
      # each item looks like
      # {:set_at=>Wed, 16 Aug 2023 21:09:13.000000000 UTC +00:00,
      #   :reminder_1=>nil,
      #   :reminder_2=>nil,
      #   :identifier=> activeRecord object for identifier}

      items.each do |item|
        resource = item[:identifier]&.latest_resource
        next if resource.nil?

        # Only send for resources where the ID ends in 00, so we can stagger the load on the curators
        next if (resource.id % 100) > 0

        # send out reminder at two weeks
        next if item[:set_at] > 2.weeks.ago || item[:reminder_1].present?

        StashEngine::UserMailer.chase_action_required1(resource).deliver_now
        create_activity(nil, r, note: 'CRON: mailed action required reminder 1')
      end
    end

    private

    def log_data_for_status(status, resource)
      text = "Mailing submitter about #{status} dataset. "
      text += resource_log_text(resource)
      log(text)
    end
  end
end
