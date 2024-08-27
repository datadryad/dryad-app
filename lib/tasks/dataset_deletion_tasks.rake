# :nocov:
namespace :dataset_deletion do

  desc 'Send monthly email reminder to the submitter when a dataset has been `in_progress` for more then 1 month'
  task in_progress_reminders: :environment do
    p 'Mailing users whose datasets have been in_progress for more then 1 months'
    StashEngine::AbandonedDatasetService.new(logging: true).send_in_progress_reminders
  end

  desc 'Send monthly email reminder to the submitter when a dataset has been in `action_required` for more then 1 month'
  task in_action_required_reminders: :environment do
    p 'Mailing users whose datasets have been action_required for more then 1 month'
    StashEngine::AbandonedDatasetService.new(logging: true).send_action_required_reminders
  end

  desc 'Send monthly email reminder to the submitter when a dataset has been in `peer_review` for more then 6 months'
  task in_peer_review_reminders: :environment do
    p 'Mailing users whose datasets have been peer_review for more then 6 months'
    StashEngine::AbandonedDatasetService.new(logging: true).send_peer_review_reminders
  end

  desc 'Withdraw datasets and send email reminder to the submitter'
  task auto_withdraw: :environment do
    p 'Mailing users whose datasets are being withdrawn'
    StashEngine::AbandonedDatasetService.new(logging: true).auto_withdraw
  end

  desc 'Send final withdraw email reminder to the submitter'
  task final_withdrawn_notification: :environment do
    p 'Mailing users whose datasets are being withdrawn'
    StashEngine::AbandonedDatasetService.new(logging: true).send_final_withdrawn_notification
  end
end
# :nocov:
