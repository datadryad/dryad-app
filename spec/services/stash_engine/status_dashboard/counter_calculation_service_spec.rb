require 'byebug'

require 'rails_helper'
require 'fileutils'

RSpec.configure(&:infer_spec_type_from_file_location!)

module StashEngine
  module StatusDashboard
    describe CounterCalculationService do
      before(:each) do
        @cc_service = StashEngine::StatusDashboard::CounterCalculationService.new
      end

      it "returns false if the log file doesn't exist" do
        result = @cc_service.check_counter_log('/badpath')
        expect(result[0]).to eq(false)
        expect(result[1]).to eq('Log file does not exist')
      end

      it 'returns false if there is no date in the file' do
        f = Rails.root.join('spec', 'fixtures', 'counter_processor', 'sample_log.txt').to_s
        result = @cc_service.check_counter_log(f)
        expect(result[0]).to eq(false)
        expect(result[1]).to eq("Log file doesn't contain an output date")
      end

      it 'returns false if the last date is long ago' do
        sample_file = Rails.root.join('spec', 'fixtures', 'counter_processor', 'sample_log.txt').to_s
        temp_file = Rails.root.join('spec', 'fixtures', 'counter_processor', 'temp_log').to_s
        contents = File.read(sample_file)
        contents.gsub!('<replace-time>', (Time.new - (86_400 * 7)).strftime('%Y-%m-%d %H:%M:%S'))
        File.write(temp_file, contents)

        result = @cc_service.check_counter_log(temp_file)
        expect(result[0]).to eq(false)
        expect(result[1]).to eq("Counter hasn't successfully processed this week")

        File.delete(temp_file)
      end

      it 'returns false if not submitted' do
        sample_file = Rails.root.join('spec', 'fixtures', 'counter_processor', 'sample_log.txt').to_s
        temp_file = Rails.root.join('spec', 'fixtures', 'counter_processor', 'temp_log').to_s
        contents = File.read(sample_file)
        contents.gsub!('<replace-time>', (Time.new - 86_400).strftime('%Y-%m-%d %H:%M:%S'))
        contents.gsub!(/^submitted/, '')
        File.write(temp_file, contents)

        result = @cc_service.check_counter_log(temp_file)
        expect(result[0]).to eq(false)
        expect(result[1]).to eq("Counter doesn't seem to have successfully submitted this week")

        File.delete(temp_file)
      end

      it 'returns true if the log file has correct output' do
        sample_file = Rails.root.join('spec', 'fixtures', 'counter_processor', 'sample_log.txt').to_s
        temp_file = Rails.root.join('spec', 'fixtures', 'counter_processor', 'temp_log').to_s
        contents = File.read(sample_file)
        contents.gsub!('<replace-time>', (Time.new - 86_400).strftime('%Y-%m-%d %H:%M:%S'))
        File.write(temp_file, contents)

        result = @cc_service.check_counter_log(temp_file)
        expect(result[0]).to eq(true)
        expect(result[1]).to eq('The counter log indicates successful submission to DataCite this week')

        File.delete(temp_file)
      end

    end
  end
end
