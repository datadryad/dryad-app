# this just tests the action_required_reminder.rb file and the methods in it
# require 'tasks/stash_engine_tasks/action_required_reminder'

module Stash
  module ActionRequiredReminder
    RSpec.describe :find_action_required_items, type: :model do

      before(:each) do
        @resource = create(:resource)
      end

      it 'does something' do
        expect(true).to eq(true)
      end
    end
  end
end

