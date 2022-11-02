require 'rails_helper'

module StashEngine
  RSpec.describe FrictionlessReport, type: :model do
    before(:each) do
      @resource = create(:resource)
      @file = create(:generic_file, resource_id: @resource.id)
    end

    describe 'associations' do
      it { should belong_to(:generic_file) }
    end

    describe 'validations' do
      it { should validate_presence_of(:generic_file) }
      it 'is not valid without a status' do
        fr = FrictionlessReport.new(generic_file: @file, status: nil)
        expect(fr).to_not be_valid
      end
      it {
        should define_enum_for(:status).with_values(
          %w[issues noissues checking error].to_h { |i| [i.to_sym, i] }
        ).backed_by_column_of_type(:string)
      }
      it 'is valid with valid attributes' do
        expect(FrictionlessReport.new(generic_file: @file, status: 'checking')).to be_valid
      end
    end
  end
end
