require 'db_spec_helper'
require 'ostruct'
require 'byebug'

module StashEngine

  describe CounterStat do

    before(:each) do
      # mock out the stat objects which are used within this class and are unit tested elsewhere
      allow_any_instance_of(Stash::EventData::Usage).to receive(:unique_dataset_investigations_count).and_return(54)
      allow_any_instance_of(Stash::EventData::Usage).to receive(:unique_dataset_requests_count).and_return(16)
      allow_any_instance_of(Stash::EventData::Citations).to receive(:results).and_return({ count: 2 }.to_ostruct)

      @identifier = Identifier.create(identifier_type: 'DOI', identifier: '10.123/456')
      @identifier.counter_stat.update(identifier_id: @identifier.id, citation_count: 5, unique_investigation_count: 105,
                                      unique_request_count: 31, updated_at: Time.new - 7.days)
    end

    describe :check_unique_investigation_count do
      xit 'updates counts if from before this week' do
        cs = @identifier.counter_stat
        expect(cs.check_unique_investigation_count).to eq(54)
      end

      xit "doesn't update counts if from this week" do
        cs = @identifier.counter_stat
        cs.update(updated_at: Time.new)
        expect(cs.check_unique_investigation_count).to eq(105)
      end
    end

    describe :check_unique_request_count do
      xit 'updates counts if from before this week' do
        cs = @identifier.counter_stat
        expect(cs.check_unique_request_count).to eq(16)
      end

      xit "doesn't update counts if from this week" do
        cs = @identifier.counter_stat
        cs.update(updated_at: Time.new)
        expect(cs.check_unique_request_count).to eq(31)
      end
    end

    describe :check_citation_count do
      xit 'updates counts if from before this week' do
        cs = @identifier.counter_stat
        expect(cs.check_citation_count).to eq(2)
      end

      xit "doesn't update counts if from this week" do
        cs = @identifier.counter_stat
        cs.update(updated_at: Time.new)
        expect(cs.check_citation_count).to eq(5)
      end
    end
  end
end
