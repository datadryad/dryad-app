module StashEngine

  class DeleteNotificationsService
    attr_reader :logging

    def initialize(logging = false)
      @logging = logging
    end

    # Send In Progress delete email notification
    # - email is sent monthly starting from first month until 1 year
    # - after 1 year the resource should get deleted
    def send_in_progress_reminders
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'in_progress' })
        .where(stash_engine_process_dates: { last_status_date: 1.year.ago.beginning_of_day..1.months.ago.end_of_day })
        .each do |resource|
        reminder_flag = 'in_progress_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
        if resource.current_curation_status == 'in_progress' &&
          resource.identifier.latest_resource_id == resource.id &&
          (last_reminder.blank? || last_reminder.created_at <= 1.month.ago)

          log("Mailing submitter about deletion of in_progress dataset. Identifier: #{resource.identifier_id}, Resource: #{resource.id} updated #{resource.updated_at}")
          StashEngine::ResourceMailer.in_progress_delete_notification(resource).deliver_now
          create_activity(reminder_flag, resource)
        end
        return true
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
    end

    # Send Action Required delete email notification
    # - email is sent monthly starting from first month until 1 year
    # - after 1 year the resource should be set to Withdrawn status
    def send_action_required_reminders
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'action_required' })
        .where(stash_engine_process_dates: { last_status_date: 1.year.ago.beginning_of_day..1.months.ago.end_of_day })
        .each do |resource|

        reminder_flag = 'action_required_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last

        if resource.current_curation_status == 'action_required' &&
          resource.identifier.latest_resource_id == resource.id &&
          (last_reminder.blank? || last_reminder.created_at <= 1.month.ago)

          log resource.user.email
          log("Mailing submitter about deletion of action_required dataset. Identifier: #{resource.identifier_id}, Resource: #{resource.id} updated #{resource.updated_at}")
          StashEngine::ResourceMailer.action_required_delete_notification(resource).deliver_now
          create_activity(reminder_flag, resource)
        end
        return true
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
    end

    # Send Peer Review delete email notification
    # - email is sent monthly starting from 6th month until 1 year
    # - after 1 year the resource should be set to Withdrawn status
    def send_peer_review_reminders
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity).joins(:process_date)
        .where(stash_engine_curation_activities: { status: 'peer_review' })
        .where(stash_engine_process_dates: { last_status_date: 1.year.ago.beginning_of_day..6.months.ago.end_of_day })
        .each do |resource|

        reminder_flag = 'peer_review_deletion_notice'
        last_reminder = resource.curation_activities.where('note LIKE ?', "%#{reminder_flag}%")&.last
        if last_reminder.blank? || last_reminder.created_at <= 1.month.ago
          log("Mailing submitter about deletion of peer_review dataset. Identifier: #{resource.identifier_id}, Resource: #{resource.id} updated #{resource.updated_at}")
          StashEngine::ResourceMailer.peer_review_delete_notification(resource).deliver_now
          create_activity(reminder_flag, resource)
        end
      rescue StandardError => e
        p "    Exception! #{e.message}"
      end
      true
    end

    private

    def create_activity(flag, resource)
      status = resource.last_curation_activity.status
      StashEngine::CurationActivity.create(
        resource_id: resource.id,
        user_id: 0,
        status: status,
        note: "#{flag} - reminded submitter that this item is still `#{status}`"
      )
    end

    def log(message)
      return unless logging

      p message
    end
  end
end
