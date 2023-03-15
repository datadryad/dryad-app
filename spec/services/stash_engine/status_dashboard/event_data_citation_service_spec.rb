require 'byebug'

require 'rails_helper'
require 'fileutils'

RSpec.configure(&:infer_spec_type_from_file_location!)

module StashEngine
  module StatusDashboard
    describe CounterCalculationService do
      before(:each) do
        @ed_service = StashEngine::StatusDashboard::EventDataCitationService.new
      end

      it "returns false if the log file doesn't exist" do
        result = @ed_service.check_citation_log('/badpath')
        expect(result[0]).to eq(false)
        expect(result[1]).to eq('Log file does not exist')
      end

      it 'returns false if there is no completion message and date in the file' do
        f = Rails.root.join('spec', 'fixtures', 'event_data_citation', 'incomplete_sample_log.txt').to_s
        result = @ed_service.check_citation_log(f)
        expect(result[0]).to eq(false)
        expect(result[1]).to eq("Log file doesn't end with completion message")
      end

      it 'returns false if the last date is long ago' do
        sample_file = Rails.root.join('spec', 'fixtures', 'event_data_citation', 'incomplete_sample_log.txt').to_s
        temp_file = Rails.root.join('spec', 'fixtures', 'event_data_citation', 'temp_log').to_s
        contents = File.read(sample_file) + "Completed populating citations at #{(Time.new - 10.days).iso8601}"
        File.write(temp_file, contents)

        result = @ed_service.check_citation_log(temp_file)
        expect(result[0]).to eq(false)
        expect(result[1]).to eq("Populating citations hasn't successfully completed this week")

        File.delete(temp_file)
      end

      it 'returns true if the log file has completed recently' do
        sample_file = Rails.root.join('spec', 'fixtures', 'event_data_citation', 'incomplete_sample_log.txt').to_s
        temp_file = Rails.root.join('spec', 'fixtures', 'event_data_citation', 'temp_log').to_s
        contents = File.read(sample_file) + "Completed populating citations at #{(Time.new - 3.days).iso8601}"
        File.write(temp_file, contents)

        result = @ed_service.check_citation_log(temp_file)
        expect(result[0]).to eq(true)
        expect(result[1]).to start_with('Completed populating citations')

        File.delete(temp_file)
      end

    end
  end
end
