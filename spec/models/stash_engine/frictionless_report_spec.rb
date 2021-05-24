require 'rails_helper'

module StashEngine
  RSpec.describe FrictionlessReport, type: :model do

    describe 'default values' do
      it 'creates model instance' do
        @resource = create(:resource)
        @file = create(:generic_file, resource_id: @resource.id)
        @frictionless_report = create(:frictionless_report, generic_file_id: @file.id)

        expect(@file.frictionless_report).to eq(@frictionless_report)
      end
    end
  end
end
