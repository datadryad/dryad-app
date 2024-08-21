module StashEngine
  describe DeleteNotificationsService do
    before do
      allow_any_instance_of(StashEngine::CurationActivity).to receive(:update_salesforce_metadata).and_return(true)
    end

    after :each do
      Timecop.return
    end

    let!(:user1) { create(:user, email: 'admin@email.test', id: 0) }
    let(:user) { create(:user, email: 'some@email.test') }
    let(:identifier) { create(:identifier) }
    let(:resource) { create(:resource, identifier_id: identifier.id, user_id: user.id) }

    describe '#send_in_progress_reminders' do
      let!(:curation_activity) { create(:curation_activity, :in_progress, resource_id: resource.id) }

      before do
        allow(StashEngine::ResourceMailer).to receive_message_chain(:in_progress_delete_notification, :deliver_now).and_return(true)
      end

      context 'when status date is sooner then one month' do
        it 'does not send notification email' do
          Timecop.travel(1.day.from_now)
          expect(StashEngine::ResourceMailer).to receive(:in_progress_delete_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_in_progress_reminders
        end
      end

      context 'when status date is older then one year' do
        it 'does not send notification email' do
          Timecop.travel(13.months.from_now)
          expect(StashEngine::ResourceMailer).to receive(:in_progress_delete_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_in_progress_reminders
        end
      end

      context 'when status date is between 1 month and one year' do
        [1, 7, 12].each do |month_num|
          it "sends notification email at #{month_num} months" do
            Timecop.travel(month_num.months.from_now)
            expect(StashEngine::ResourceMailer).to receive_message_chain(:in_progress_delete_notification, :deliver_now).with(resource).with(no_args)
            expect(subject).to receive(:create_activity).with('in_progress_deletion_notice', resource).once

            subject.send_in_progress_reminders
          end
        end

        it 'sends only one email per month' do
          resource.last_curation_activity.update!(created_at: 1.months.ago, updated_at: 1.months.ago)
          subject.send(:create_activity, 'in_progress_deletion_notice', resource)

          expect(StashEngine::ResourceMailer).to receive(:in_progress_delete_notification).never

          [1.second, 1.day, 2.week, 1.month - 1.day].each do |period|
            Timecop.travel(period) do
              subject.send_in_progress_reminders
            end
          end
        end

        it 'sends second email after a month' do
          resource.last_curation_activity.update!(created_at: 1.months.ago, updated_at: 1.months.ago)
          subject.send(:create_activity, 'in_progress_deletion_notice', resource)

          expect(StashEngine::ResourceMailer).to receive(:in_progress_delete_notification).once
          Timecop.travel(1.month) do
            subject.send_in_progress_reminders
          end
        end
      end
    end

    describe '#send_action_required_reminders' do
      let!(:curation_activity) { create(:curation_activity, status: 'action_required', resource_id: resource.id) }

      before do
        allow(StashEngine::ResourceMailer).to receive_message_chain(:action_required_delete_notification, :deliver_now).and_return(true)
        resource.last_curation_activity.update!(status: 'action_required')
      end

      context 'when status date is sooner then one month' do
        it 'does not send notification email' do
          Timecop.travel(1.day.from_now)
          expect(StashEngine::ResourceMailer).to receive(:action_required_delete_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_action_required_reminders
        end
      end

      context 'when status date is older then one year' do
        it 'does not send notification email' do
          Timecop.travel(13.months.from_now)
          expect(StashEngine::ResourceMailer).to receive(:action_required_delete_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_action_required_reminders
        end
      end

      context 'when status date is between 1 month and one year' do
        [1, 7, 12].each do |month_num|
          it "sends notification email at #{month_num} months" do
            Timecop.travel(month_num.months.from_now)

            expect(StashEngine::ResourceMailer).to receive_message_chain(:action_required_delete_notification,
                                                                         :deliver_now).with(resource).with(no_args)
            expect(subject).to receive(:create_activity).with('action_required_deletion_notice', resource).once

            subject.send_action_required_reminders
          end
        end

        it 'sends only one email per month' do
          resource.last_curation_activity.update!(created_at: 2.months.ago)
          subject.send(:create_activity, 'action_required_deletion_notice', resource)

          expect(StashEngine::ResourceMailer).to receive(:action_required_delete_notification).never

          [1.second, 1.day, 2.week, 1.month - 1.day].each do |period|
            Timecop.travel(period) do
              subject.send_action_required_reminders
            end
          end
        end

        it 'sends second email after a month' do
          resource.last_curation_activity.update!(created_at: 2.months.ago)
          subject.send(:create_activity, 'action_required_deletion_notice', resource)

          expect(StashEngine::ResourceMailer).to receive(:action_required_delete_notification).once
          Timecop.travel(2.month + 1.day) do
            subject.send_action_required_reminders
          end
        end
      end
    end

    describe '#send_peer_review_reminders' do
      let!(:curation_activity) { create(:curation_activity, status: 'peer_review', resource_id: resource.id) }

      before do
        allow(StashEngine::ResourceMailer).to receive_message_chain(:action_required_delete_notification, :deliver_now).and_return(true)
        resource.last_curation_activity.update!(status: 'peer_review')
      end

      context 'when status date is sooner then one month' do
        before do
          resource.last_curation_activity.update!(created_at: 1.day.ago)
        end
        it 'does not send notification email' do
          expect(StashEngine::ResourceMailer).to receive(:peer_review_delete_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_peer_review_reminders
        end
      end

      context 'when status date is older then one year' do
        before do
          resource.last_curation_activity.update!(created_at: 13.months.ago)
        end

        it 'does not send notification email' do
          expect(StashEngine::ResourceMailer).to receive(:peer_review_delete_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_peer_review_reminders
        end
      end

      context 'when status date is between 6 months and 1 year' do
        [6, 7, 9, 12].each do |month_num|
          it "sends notification email at #{month_num} months" do
            Timecop.travel(month_num.months.from_now)

            expect(StashEngine::ResourceMailer).to receive_message_chain(:peer_review_delete_notification, :deliver_now).with(resource).with(no_args)
            expect(subject).to receive(:create_activity).with('peer_review_deletion_notice', resource).once

            subject.send_peer_review_reminders
          end
        end

        it 'sends only one email per month' do
          Timecop.travel(6.months.from_now) do
            subject.send(:create_activity, 'peer_review_deletion_notice', resource)
          end
          expect(StashEngine::ResourceMailer).to receive(:peer_review_delete_notification).never

          [1.second, 1.day, 2.week, 1.month - 1.day].each do |period|
            Timecop.travel(6.months.from_now + period) do
              subject.send_peer_review_reminders
            end
          end
        end

        it 'sends second email after a month' do
          Timecop.travel(6.month.from_now) do
            subject.send(:create_activity, 'peer_review_deletion_notice', resource)
          end

          expect(StashEngine::ResourceMailer).to receive(:peer_review_delete_notification).once
          Timecop.travel(7.month.from_now) do
            subject.send_peer_review_reminders
          end
        end
      end
    end

    describe '#send_withdrawn_notification' do
      let!(:curation_activity) { create(:curation_activity, status: 'peer_review', resource_id: resource.id) }

      before do
        allow(StashEngine::ResourceMailer).to receive_message_chain(:send_set_to_withdrawn_notification, :deliver_now).and_return(true)
        resource.last_curation_activity.update!(status: 'peer_review')
      end

      context 'when status date is sooner then one year' do
        it 'does not send notification email' do
          Timecop.travel(11.months.from_now)
          expect(StashEngine::ResourceMailer).to receive(:send_set_to_withdrawn_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_withdrawn_notification
        end
      end

      context 'when status date is older then 1 year' do
        it 'creates withdrawn activity notification at 1 year' do
          Timecop.travel(1.year.from_now)

          expect(subject).to receive(:create_activity).with('withdrawn_email_notice', resource, {
                                                              note: 'withdrawn_email_notice - notification that this item was set to `withdrawn`',
                                                              status: 'withdrawn'
                                                            }).once

          subject.send_withdrawn_notification
        end

        it 'sends notification email at 1 year' do
          Timecop.travel(1.year.from_now)

          expect(StashEngine::ResourceMailer).to receive_message_chain(:send_set_to_withdrawn_notification, :deliver_now).with(resource).with(no_args)

          subject.send_withdrawn_notification
        end

        it 'sends only one email ever' do
          Timecop.travel(1.year.from_now) do
            subject.send(:create_activity, 'withdrawn_email_notice', resource)
          end
          expect(StashEngine::ResourceMailer).to receive(:send_set_to_withdrawn_notification).never

          [1.second, 1.day, 2.week, 1.month, 10.years].each do |period|
            Timecop.travel(1.year.from_now + period) do
              subject.send_withdrawn_notification
            end
          end
        end
      end
    end

    describe '#send_withdrawn_notification' do
      context 'for in peer_review resource' do
        let!(:curation_activity) { create(:curation_activity, status: 'peer_review', resource_id: resource.id) }

        before do
          allow(StashEngine::ResourceMailer).to receive_message_chain(:send_set_to_withdrawn_notification, :deliver_now).and_return(true)
          resource.last_curation_activity.update!(status: 'peer_review')
        end

        context 'when status date is sooner then one year' do
          it 'does not send notification email' do
            Timecop.travel(11.months.from_now)
            expect(StashEngine::ResourceMailer).to receive(:send_set_to_withdrawn_notification).never
            expect(subject).to receive(:create_activity).never

            subject.send_withdrawn_notification
          end
        end

        context 'when status date is older then 1 year' do
          it 'creates withdrawn activity notification at 1 year' do
            Timecop.travel(1.year.from_now)

            expect(subject).to receive(:create_activity).with('withdrawn_email_notice', resource, {
                                                                note: 'withdrawn_email_notice - notification that this item was set to `withdrawn`',
                                                                status: 'withdrawn'
                                                              }).once

            subject.send_withdrawn_notification
          end

          it 'sends notification email at 1 year' do
            Timecop.travel(1.year.from_now)

            expect(StashEngine::ResourceMailer).to receive_message_chain(:send_set_to_withdrawn_notification,
                                                                         :deliver_now).with(resource).with(no_args)

            subject.send_withdrawn_notification
          end

          it 'sends only one email ever' do
            Timecop.travel(1.year.from_now) do
              subject.send(:create_activity, 'withdrawn_email_notice', resource)
            end
            expect(StashEngine::ResourceMailer).to receive(:send_set_to_withdrawn_notification).never

            [1.second, 1.day, 2.week, 1.month, 10.years].each do |period|
              Timecop.travel(1.year.from_now + period) do
                subject.send_withdrawn_notification
              end
            end
          end
        end
      end

      context 'for in action_required resource' do
        let!(:curation_activity) { create(:curation_activity, status: 'action_required', resource_id: resource.id) }

        before do
          allow(StashEngine::ResourceMailer).to receive_message_chain(:send_set_to_withdrawn_notification, :deliver_now).and_return(true)
          resource.last_curation_activity.update!(status: 'action_required')
        end

        context 'when status date is sooner then one year' do
          it 'does not send notification email' do
            Timecop.travel(11.months.from_now)
            expect(StashEngine::ResourceMailer).to receive(:send_set_to_withdrawn_notification).never
            expect(subject).to receive(:create_activity).never

            subject.send_withdrawn_notification
          end
        end

        context 'when status date is older then 1 year' do
          it 'creates withdrawn activity notification at 1 year' do
            Timecop.travel(1.year.from_now)

            expect(subject).to receive(:create_activity).with('withdrawn_email_notice', resource, {
                                                                note: 'withdrawn_email_notice - notification that this item was set to `withdrawn`',
                                                                status: 'withdrawn'
                                                              }).once

            subject.send_withdrawn_notification
          end

          it 'sends notification email at 1 year' do
            Timecop.travel(1.year.from_now)

            expect(StashEngine::ResourceMailer).to receive_message_chain(:send_set_to_withdrawn_notification,
                                                                         :deliver_now).with(resource).with(no_args)

            subject.send_withdrawn_notification
          end

          it 'sends only one email ever' do
            Timecop.travel(1.year.from_now) do
              subject.send(:create_activity, 'withdrawn_email_notice', resource)
            end
            expect(StashEngine::ResourceMailer).to receive(:send_set_to_withdrawn_notification).never

            [1.second, 1.day, 2.week, 1.month, 10.years].each do |period|
              Timecop.travel(1.year.from_now + period) do
                subject.send_withdrawn_notification
              end
            end
          end
        end
      end
    end

    describe '#send_final_withdrawn_notification' do
      let!(:curation_activity) { create(:curation_activity, status: 'withdrawn', resource_id: resource.id) }

      before do
        allow(StashEngine::ResourceMailer).to receive_message_chain(:send_final_withdrawn_notification, :deliver_now).and_return(true)
        resource.last_curation_activity.update!(status: 'withdrawn')
      end

      context 'when status date is sooner then 9 months' do
        it 'does not send notification email' do
          Timecop.travel(9.months.from_now - 1.day)
          expect(StashEngine::ResourceMailer).to receive(:send_final_withdrawn_notification).never
          expect(subject).to receive(:create_activity).never

          subject.send_final_withdrawn_notification
        end
      end

      context 'when status date is older then 9 months' do
        it 'sends notification email at 9 months' do
          Timecop.travel(9.months.from_now)

          expect(StashEngine::ResourceMailer).to receive_message_chain(:send_final_withdrawn_notification, :deliver_now).with(resource).with(no_args)
          expect(subject).to receive(:create_activity).with('final_withdrawn_email_notice', resource).once

          subject.send_final_withdrawn_notification
        end

        it 'sends only one email ever' do
          Timecop.travel(9.months.from_now) do
            subject.send(:create_activity, 'final_withdrawn_email_notice', resource)
          end
          expect(StashEngine::ResourceMailer).to receive(:send_final_withdrawn_notification).never

          [1.second, 1.day, 2.week, 1.month, 10.years].each do |period|
            Timecop.travel(9.months.from_now + period) do
              subject.send_final_withdrawn_notification
            end
          end
        end
      end
    end

    describe '#create_activity' do
      let(:curation_activity) { create(:curation_activity, status: 'in_progress', resource_id: resource.id) }
      it 'creates a new CurationActivity record' do
        resource.last_curation_activity.update!(created_at: 1.day.ago)
        expect { subject.send(:create_activity, 'flag', resource) }.to change { StashEngine::CurationActivity.count }.by(1)
      end

      it 'sets proper data' do
        record = subject.send(:create_activity, 'flag', resource)
        expect(record.note).to eq('flag - reminded submitter that this item is still `in_progress`')
        expect(record.status).to eq('in_progress')
        expect(record.resource_id).to eq(resource.id)
        expect(record.user_id).to eq(0)
      end
    end

    describe '#log' do
      it 'prints message with logging true' do
        expect do
          subject.class.new(logging: true).send(:log, 'delete_notification_message_with_logs')
        end.to output(/delete_notification_message_with_logs/).to_stdout
      end

      it 'does not print the message with logging false or missing' do
        expect do
          subject.class.new(logging: false).send(:log, 'delete_notification_message_with_logs')
        end.not_to output(/delete_notification_message_with_logs/).to_stdout
        expect do
          subject.class.new.send(:log, 'delete_notification_message_with_logs')
        end.not_to output(/delete_notification_message_with_logs/).to_stdout
      end
    end
  end
end