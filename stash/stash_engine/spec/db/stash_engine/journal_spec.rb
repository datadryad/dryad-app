require 'db_spec_helper'

module StashEngine
  describe Journal do

    before(:each) do
      @journal = Journal.create(issn: '1234-5678')
    end

    describe '#will_pay?' do
      it 'returns true when there is a PREPAID plan' do
        allow(@journal).to receive('payment_plan_type').and_return('PREPAID')
        expect(@journal.will_pay?).to be(true)
      end

      it 'returns true when there is a SUBSCRIPTION plan' do
        allow(@journal).to receive('payment_plan_type').and_return('SUBSCRIPTION')
        expect(@journal.will_pay?).to be(true)
      end

      it 'returns false when there is a no plan' do
        allow(@journal).to receive('payment_plan_type').and_return(nil)
        expect(@journal.will_pay?).to be(false)
      end

      it 'returns false when there is an unrecognized plan' do
        allow(@journal).to receive('payment_plan_type').and_return('BOGUS-PLAN')
        expect(@journal.will_pay?).to be(false)
      end
    end

  end
end
