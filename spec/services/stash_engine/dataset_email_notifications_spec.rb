require 'rake'

module StashEngine
  describe 'DatasetEmailNotifications' do
    before do
      allow_any_instance_of(StashEngine::CurationActivity).to receive(:update_salesforce_metadata).and_return(true)
    end

    after :each do
      Timecop.return
    end

    let!(:user1) { create(:user, email: 'admin@email.test', id: 0) }
    let(:user) { create(:user, email: 'some@email.test') }
    let(:identifier) { create(:identifier) }
    let!(:resource) { create(:resource, identifier_id: identifier.id, user_id: user.id) }

    describe 'in_progress resource lifetime' do
      before do
        sleep 1
        create(:curation_activity, status: 'in_progress', resource_id: resource.id)
        resource.current_resource_state.update(resource_state: 'in_progress')
      end

      context 'called at 3 days, sends 1 email' do
        it_should_behave_like 'send email notifications tasks', 1, (3.days + 10.seconds).from_now
      end

      context 'called at 14 days, sends 1 email' do
        # sends only 3 days email reminder
        it_should_behave_like 'send email notifications tasks', 1, (14.days + 10.seconds).from_now
      end

      #  sends 3 days email reminder
      #  sends monthly reminder
      [1, 6, 11].each do |months_number|
        context "called at #{months_number} months, sends 2 emails" do
          it_should_behave_like 'send email notifications tasks', 2, (months_number.months + 10.seconds).from_now
        end
      end

      context 'called after 1 year, sends 1 email' do
        # sends only 3 days email reminder
        # no monthly reminder since it should be deleted at 1 year
        it_should_behave_like 'send email notifications tasks', 1, (1.year + 10.seconds).from_now
      end
    end

    describe 'processing resource lifetime' do
      before do
        sleep 1
        create(:curation_activity, status: 'processing', resource_id: resource.id)
        resource.current_resource_state.update(resource_state: 'processing')
      end

      #  sends no monthly reminder fro this status
      [1, 6, 11, 12, 24].each do |months_number|
        context "called at #{months_number} months, sends 2 emails" do
          it_should_behave_like 'send email notifications tasks', 0, (months_number.months + 10.seconds).from_now
        end
      end
    end

    describe 'action_required resource lifetime' do
      before do
        sleep 1
        create(:curation_activity, status: 'action_required', resource_id: resource.id)
        resource.current_resource_state.update(resource_state: 'processing')
      end

      context 'called at 3 days, sends no email' do
        it_should_behave_like 'send email notifications tasks', 0, (3.days + 10.seconds).from_now
      end

      context 'called at 14 days, sends 1 email' do
        # sends 2 weeks email reminder
        it_should_behave_like 'send email notifications tasks', 1, (14.days + 10.seconds).from_now
      end

      #  sends 2 weeks email reminder
      #  sends monthly reminder
      [1, 6, 11].each do |months_number|
        context "called at #{months_number} months, sends 2 emails" do
          it_should_behave_like 'send email notifications tasks', 2, (months_number.months + 10.seconds).from_now
        end
      end

      context 'called after 1 year, sends no email' do
        # no 2 weeks reminder
        # no monthly reminders since it should be withdrawn at 1 year
        it_should_behave_like 'send email notifications tasks', 0, (12.month + 10.seconds).from_now
      end
    end

    describe 'peer_review resource lifetime' do
      before do
        sleep 1
        create(:curation_activity, status: 'peer_review', resource_id: resource.id)
        resource.current_resource_state.update(resource_state: 'processing')
      end

      context 'called at 14 days, sends no emails' do
        it_should_behave_like 'send email notifications tasks', 0, (14.days + 10.seconds).from_now
      end

      #  sends no monthly reminder under 6 months
      [1, 3, 5].each do |months_number|
        context "called at #{months_number} months, sends no emails" do
          it_should_behave_like 'send email notifications tasks', 0, (months_number.months + 10.seconds).from_now
        end
      end

      # sends monthly reminder between 6 months and 1 year
      [6, 10, 11].each do |months_number|
        context "called at #{months_number} months, sends 1 email" do
          it_should_behave_like 'send email notifications tasks', 1, (months_number.months + 10.seconds).from_now
        end
      end

      context 'called after 1 year, sends no email' do
        # no monthly reminders since it should be withdrawn at 1 year
        it_should_behave_like 'send email notifications tasks', 0, (1.year + 10.seconds).from_now
      end
    end
  end
end
