RSpec.shared_examples('send email notifications tasks') do |count, date|
  it 'should send emails' do
    Timecop.travel(date + 1.day) do
      expect do
        Rake::Task['identifiers:in_progress_reminder_1_day'].execute
        Rake::Task['identifiers:in_progress_reminder_3_days'].execute
        Rake::Task['dataset_deletion:in_progress_reminders'].execute
        Rake::Task['identifiers:action_required_reminder'].execute
        Rake::Task['dataset_deletion:in_action_required_reminders'].execute
        Rake::Task['dataset_deletion:in_awaiting_payment_reminders'].execute
        Rake::Task['dataset_deletion:in_peer_review_reminders'].execute
        Rake::Task['dataset_deletion:auto_withdraw'].execute
        Rake::Task['dataset_deletion:final_withdrawn_notification'].execute
      end.to change { ActionMailer::Base.deliveries.count }.by(count)
    end
  end
end
