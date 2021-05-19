require 'rails_helper'
require 'byebug'
require 'cgi'

describe 'counter:cop_manual', type: :task do
  before(:each) do
    @path = Rails.root.join('spec/fixtures/counter_processor')
    ENV['JSON_DIRECTORY'] = @path.to_s

    # some items to spot check
    @test_items = { '10.5061/dryad.234' => { investigation: 192, request: 174 },
                    '10.5061/dryad.1992' => { investigation: 62, request: 9 },
                    '10.5061/dryad.1924' => { investigation: 69, request: 4 },
                    '10.5061/dryad.7881' => { investigation: 18, request: 4 },
                    '10.5061/dryad.1159' => { investigation: 34, request: 0 },
                    '10.5061/dryad.1421' => { investigation: 10, request: 6 } }
    @test_items.each_key do |k|
      create(:identifier, identifier: k)
    end
  end

  it 'executes the task and creates the stats in the database based on json files' do
    task.execute
    @test_items.each_pair do |k, v|
      doi_obj = StashEngine::Identifier.find_by_identifier(k)
      stat = doi_obj.counter_stat
      expect(stat.unique_investigation_count).to eq(v[:investigation])
      expect(stat.unique_request_count).to eq(v[:request])
    end
  end
end
