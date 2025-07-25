module Reminders
  class AbandonedDatasetService < Reminders::BaseService

    # Send In Progress delete email notification
    # - email is sent monthly starting from first month until 1 year
    # - after 1 year the resource should get deleted
    def send_in_progress_reminders
      # return if time is less than 1 month since the bulk still in_progress email was sent
      # This can be deleted after 21 Aug 2025
      return true if Time.current < '21-08-2025'.to_date

      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'in_progress' })
        .where(stash_engine_process_dates: { delete_calculation_date: (1.year - 1.day).ago.beginning_of_day..1.months.ago.end_of_day })
        .each do |resource|
        reminder_flag = 'in_progress_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
        if resource.current_curation_status == 'in_progress' &&
          resource.identifier.latest_resource_id == resource.id &&
          (last_reminder.blank? || last_reminder.created_at <= 1.month.ago)

          log_data_for_status('in_progress', resource)
          StashEngine::ResourceMailer.in_progress_delete_notification(resource).deliver_now
          create_activity(reminder_flag, resource)
        end
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
      true
    end

    # Send Action Required delete email notification
    # - email is sent monthly starting from first month until 1 year
    # - after 1 year the resource should be set to Withdrawn status
    def send_action_required_reminders
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'action_required' })
        .where(stash_engine_process_dates: { delete_calculation_date: (1.year - 1.day).ago.beginning_of_day..1.months.ago.end_of_day })
        .each do |resource|

        # Only send for resources where the ID ends in 00, so we can stagger the load on the curators
        next if (resource.id % 100) > 0

        reminder_flag = 'action_required_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last

        if resource.current_curation_status == 'action_required' &&
          resource.identifier.latest_resource_id == resource.id &&
          (last_reminder.blank? || last_reminder.created_at <= 1.month.ago)

          log_data_for_status('action_required', resource)
          StashEngine::ResourceMailer.action_required_delete_notification(resource).deliver_now
          create_activity(reminder_flag, resource)
        end
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
      true
    end

    # Send Action Required delete email notification from manual triggered script
    # - sends older ones first
    # - receives a number of emails it should send
    # Usage: StashEngine::AbandonedDatasetService.new(logging: true).send_manual_action_required_emails(1)
    def send_manual_action_required_emails(count)
      emails_sent = 0

      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'action_required' })
        .where(stash_engine_process_dates: { delete_calculation_date: (1.year - 1.day).ago.beginning_of_day..1.months.ago.end_of_day })
        .order('stash_engine_process_dates.last_status_date asc')
        .each do |resource|

        reminder_flag = 'action_required_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last

        if resource.current_curation_status == 'action_required' &&
          resource.identifier.latest_resource_id == resource.id &&
          (last_reminder.blank? || last_reminder.created_at <= 1.month.ago)

          log_data_for_status('action_required', resource)
          StashEngine::ResourceMailer.action_required_delete_notification(resource).deliver_now
          emails_sent += 1
          create_activity(reminder_flag, resource)
        end

        return true if emails_sent == count
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
      true
    end

    # Send Peer Review delete email notification
    # - email is sent monthly starting from 6th month until 1 year
    # - after 1 year the resource should be set to Withdrawn status
    def send_peer_review_reminders
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'peer_review' })
        .where(stash_engine_process_dates: { delete_calculation_date: (1.year - 1.day).ago.beginning_of_day..6.months.ago.end_of_day })
        .each do |resource|

        reminder_flag = 'peer_review_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
        if last_reminder.blank? || last_reminder.created_at <= 1.month.ago
          log_data_for_status('peer_review', resource)
          StashEngine::ResourceMailer.peer_review_delete_notification(resource).deliver_now
          create_activity(reminder_flag, resource)
        end
      rescue StandardError => e
        log "    Exception! #{e.message}"
      end
      true
    end

    # Withdraw dataset
    # - withdrawn email is sent once at 1 year
    # - the resource is set to Withdrawn status
    # def send_withdrawn_notification
    def auto_withdraw
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: %w[peer_review action_required] })
        .where('stash_engine_process_dates.delete_calculation_date <= ?', 1.year.ago.end_of_day)
        .each do |resource|

        # Do not withdraw if this dataset has ever been published
        next if %w[published embargoed].include?(resource.identifier&.calculated_pub_state)

        reminder_flag = 'withdrawn_email_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
        next if last_reminder.present?

        status_updated = create_activity(reminder_flag, resource, status: 'withdrawn',
                                                                  note: "#{reminder_flag} - notification that this item was set to `withdrawn`")

        if status_updated
          log("Mailing submitter about setting dataset to withdrawn. #{resource_log_text(resource)}")
          StashEngine::ResourceMailer.send_set_to_withdrawn_notification(resource).deliver_now
        end
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
      true
    end

    # Send final withdrawn email notification
    # - email is sent once, 9 months after the resource was withdraw
    # - the email is NOT sent if resource was withdrawn by a curator
    # - the email is NOT sent if resource was published before
    def send_final_withdrawn_notification
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'withdrawn' })
        .where('stash_engine_process_dates.last_status_date <= ?', 9.months.ago.end_of_day)
        .each do |resource|
        next if resource.curation_activities.pluck(:status).uniq.include?('published')
        next if resource.withdrawn_by_curator?

        reminder_flag = 'final_withdrawn_email_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
        next if last_reminder.present?

        log("Mailing submitter as final withdrawn notification. #{resource_log_text(resource)}")
        StashEngine::ResourceMailer.send_final_withdrawn_notification(resource).deliver_now
        create_activity(reminder_flag, resource)
      rescue StandardError => e
        log "    Exception! #{e.message}"
      end
      true
    end
  end
end
