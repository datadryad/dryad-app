# this just tests the action_required_reminder.rb file and the methods in it
# require 'tasks/stash_engine_tasks/action_required_reminder'

module Stash
  module ActionRequiredReminder
    RSpec.describe :find_action_required_items, type: :model do

      include Mocks::Salesforce

      before(:each) do
        mock_salesforce!
        @resource = create(:resource)
        create(:curation_activity_no_callbacks, resource: @resource, status: 'processing', created_at: 3.months.ago, updated_at: 3.months.ago)
        create(:curation_activity_no_callbacks, resource: @resource, status: 'submitted', created_at: 3.months.ago, updated_at: 3.months.ago)
        create(:curation_activity_no_callbacks, resource: @resource, status: 'submitted', note: 'Status change email sent to author', created_at: 3.months.ago, updated_at: 3.months.ago)
        create(:curation_activity_no_callbacks, resource: @resource, status: 'curation', created_at: 3.months.ago, updated_at: 3.months.ago)
      end

      it "gets the date for action required when it's latest state" do
        dt = 10.weeks.ago
        saved_item = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', created_at: dt, updated_at: dt)
        items = Stash::ActionRequiredReminder.find_action_required_items

        expect(items.length).to eq(1)
        expect(items.first[:set_at]).to eq(saved_item.updated_at)
      end

      it "gets the date for action required when it's gone in and out of it before" do
        create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', note: 'poop', created_at: 12.weeks.ago, updated_at: 12.weeks.ago)
        create(:curation_activity_no_callbacks, resource: @resource, status: 'curation', created_at: 12.weeks.ago, updated_at: 12.weeks.ago)

        dt = 10.weeks.ago
        saved_item = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', created_at: dt, updated_at: dt)
        items = Stash::ActionRequiredReminder.find_action_required_items

        expect(items.length).to eq(1)
        expect(items.first[:set_at]).to eq(saved_item.updated_at)
      end

      it 'gets multiple entries based on many notifications' do
        saved_start = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', created_at: 10.weeks.ago, updated_at: 10.weeks.ago)

        saved_remind1 = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', note: 'CRON: mailed action required reminder 1', created_at: 8.weeks.ago, updated_at: 8.weeks.ago)

        saved_remind2 = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', note: 'CRON: mailed action required reminder 2', created_at: 6.weeks.ago, updated_at: 6.weeks.ago)

        items = Stash::ActionRequiredReminder.find_action_required_items

        expect(items.length).to eq(1)
        expect(items.first[:set_at]).to eq(saved_start.updated_at)
        expect(items.first[:reminder_1]).to eq(saved_remind1.updated_at)
        expect(items.first[:reminder_2]).to eq(saved_remind2.updated_at)
      end

      it 'ignores withdrawn as action required after 3rd reminder' do
        saved_start = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', created_at: 10.weeks.ago, updated_at: 10.weeks.ago)

        saved_remind1 = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', note: 'CRON: mailed action required reminder 1', created_at: 8.weeks.ago, updated_at: 8.weeks.ago)

        saved_remind2 = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', note: 'CRON: mailed action required reminder 2', created_at: 6.weeks.ago, updated_at: 6.weeks.ago)

        saved_remind3 = create(:curation_activity_no_callbacks, resource: @resource, status: 'action_required', note: 'CRON: mailed action required reminder 3', created_at: 4.weeks.ago, updated_at: 4.weeks.ago)
        saved_remind3 = create(:curation_activity_no_callbacks, resource: @resource, status: 'withdrawn', note: 'withdrawing for action required', created_at: 13.days.ago, updated_at: 13.days.ago)

        items = Stash::ActionRequiredReminder.find_action_required_items

        expect(items.length).to eq(0)
      end
    end
  end
end

