module Reminders
  describe DatasetRemindersService do
    include Mocks::Salesforce

    before do
      today = Date.today
      # Set the fake time to the 20th of the current month and year
      # So we do not have to handle dates of 29, 30, 31 that we travel to and do not exist, like on February
      fake_time = Time.new(today.year, today.month, 20, 12, 0, 0) # 12:00 noon on 20th
      Timecop.freeze(fake_time)

      allow_any_instance_of(StashEngine::CurationActivity).to receive(:update_salesforce_metadata).and_return(true)
    end

    after do
      Timecop.return
    end

    let!(:user1) { create(:user, email: 'admin@email.test', id: 0) }
    let(:user) { create(:user, email: 'some@email.test') }
    let(:identifier) { create(:identifier, created_at: 3.days.ago) }
    let(:resource) { create(:resource, identifier_id: identifier.id, user_id: user.id) }

    describe '#send_in_progress_reminders_by_day' do
      let!(:curation_activity) { create(:curation_activity, :in_progress, resource_id: resource.id) }

      before do
        allow(StashEngine::UserMailer).to receive_message_chain(:in_progress_reminder, :deliver_now).and_return(true)
      end

      context 'with 1 day' do
        context 'when status date is less than 1 day' do
          it 'does not send any email' do
            Timecop.travel(23.hours.from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).never
            expect(subject).to receive(:create_activity).never

            subject.send_in_progress_reminders_by_day(1)
          end
        end

        context 'when status date is older then one day' do
          it 'sends in_progress_reminder notification email' do
            Timecop.travel(25.hours.from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).with(resource).once
            expect(subject).to receive(:create_activity).once

            subject.send_in_progress_reminders_by_day(1)
          end

          it 'sends only in_progress_reminder notification email for current days number' do
            Timecop.travel(25.hours.from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).with(resource).once

            subject.send_in_progress_reminders_by_day(1)
            subject.send_in_progress_reminders_by_day(1)
          end

          it 'does not send in_progress_reminder if is more than 2 days ago' do
            Timecop.travel(4.days.from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).with(resource).never
            expect(subject).to receive(:create_activity).never

            subject.send_in_progress_reminders_by_day(1)
          end
        end
      end

      context 'with 3 days' do
        context 'when status date is less than 3 days' do
          it 'does not send any email' do
            Timecop.travel((3.days - 1.minute).from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).never
            expect(subject).to receive(:create_activity).never

            subject.send_in_progress_reminders_by_day(3)
          end
        end

        context 'when status date is older then 3 days' do
          it 'sends in_progress_reminder notification email' do
            Timecop.travel((3.days + 1.minute).from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).with(resource).once
            expect(subject).to receive(:create_activity).once

            subject.send_in_progress_reminders_by_day(3)
          end

          it 'sends only in_progress_reminder notification email for current days number' do
            Timecop.travel((3.days + 1.minute).from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).with(resource).once

            subject.send_in_progress_reminders_by_day(3)
            subject.send_in_progress_reminders_by_day(3)
          end

          it 'does not send in_progress_reminder if is more than 4 days ago' do
            Timecop.travel(6.days.from_now)
            expect(StashEngine::UserMailer).to receive(:in_progress_reminder).with(resource).never
            expect(subject).to receive(:create_activity).never

            subject.send_in_progress_reminders_by_day(3)
          end
        end
      end
    end

    describe '#action_required_reminder' do
      let(:resource) { create(:resource, identifier_id: identifier.id, user_id: user.id, id: 10_000_000) }
      let!(:curation_activity) { create(:curation_activity, :in_progress, resource_id: resource.id) }
      let!(:curation_activity) { create(:curation_activity, :action_required, resource_id: resource.id) }

      before do
        Timecop.travel(3.months.ago) do
          mock_salesforce!
          create(:curation_activity_no_callbacks, resource: resource, status: 'processing')
          create(:curation_activity_no_callbacks, resource: resource, status: 'submitted')
          create(:curation_activity_no_callbacks, resource: resource, status: 'submitted', note: 'Status change email sent to author')
          create(:curation_activity_no_callbacks, resource: resource, status: 'curation')
          create(:curation_activity_no_callbacks, resource: resource, status: 'in_progress')
        end
        create(:curation_activity_no_callbacks, resource: resource, status: 'action_required')
        allow(StashEngine::UserMailer).to receive_message_chain(:chase_action_required1, :deliver_now).and_return(true)
      end

      context 'when status date is less than 2 weeks' do
        it 'does not send any email' do
          Timecop.travel((2.weeks - 1.hour).from_now)
          expect(StashEngine::UserMailer).to receive(:in_progress_reminder).never
          expect(subject).to receive(:create_activity).never

          subject.action_required_reminder
        end
      end

      context 'when status date is older then one day' do
        it 'sends in_progress_reminder notification email' do
          Timecop.travel((2.weeks + 1.hour).from_now)

          expect(StashEngine::UserMailer).to receive(:chase_action_required1).with(resource).once
          expect(subject).to receive(:create_activity).once

          subject.action_required_reminder
        end

        it 'sends only in_progress_reminder notification email for current days number' do
          Timecop.travel((2.months + 1.hour).from_now)
          expect(StashEngine::UserMailer).to receive(:chase_action_required1).with(resource).once

          subject.action_required_reminder
          subject.action_required_reminder
        end
      end

    end
  end
end
