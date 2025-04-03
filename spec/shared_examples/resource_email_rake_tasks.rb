RSpec.shared_examples('send email notifications tasks') do |count, date|
  it 'should send emails' do
    Timecop.travel(date + 1.day) do
      expect do
        Rake::Task['identifiers:in_progess_reminder'].execute
        Rake::Task['dataset_deletion:in_progress_reminders'].execute
        Rake::Task['identifiers:action_required_reminder'].execute
        Rake::Task['dataset_deletion:in_action_required_reminders'].execute
        Rake::Task['dataset_deletion:in_peer_review_reminders'].execute
        Rake::Task['dataset_deletion:auto_withdraw'].execute
        Rake::Task['dataset_deletion:final_withdrawn_notification'].execute
      end.to change { ActionMailer::Base.deliveries.count }.by(count)
    end
  end
end

RSpec.shared_examples('calling FeeCalculatorService') do |type|
  it "calculates with #{type} type" do
    expect(FeeCalculatorService).to receive_message_chain(:new, :calculate).with(type).with(options, resource: resource).and_return({})
    described_class.new(resource).calculate(options)
  end
end
