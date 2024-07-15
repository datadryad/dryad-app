# :nocov:
# rubocop:disable Metrics/BlockLength
namespace :dataset_deletion do

  desc 'Send monthly email reminder to the submitter when a dataset has been `in_progress` for more then 1 month'
  task in_progess_reminder: :environment do
    p 'Mailing users whose datasets have been in_progress for more then 1 months'
    StashEngine::DeleteNotificationsService.new(true).send_in_progress_reminders
  end

  desc 'Send monthly email reminder to the submitter when a dataset has been in `action_required` for more then 1 month'
  task in_aar_reminder: :environment do
    p 'Mailing users whose datasets have been action_required for more then 1 month'
    StashEngine::DeleteNotificationsService.new(true).send_action_required_reminders
  end

  desc 'Send monthly email reminder to the submitter when a dataset has been in `peer_review` for more then 6 months'
  task in_ppr_reminder: :environment do
    p 'Mailing users whose datasets have been peer_review for more then 6 months'
    StashEngine::DeleteNotificationsService.new(true).send_peer_review_reminders
  end
end
# rubocop:enable Metrics/BlockLength
# :nocov:
