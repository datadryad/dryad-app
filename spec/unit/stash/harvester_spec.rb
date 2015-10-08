require 'spec_helper'

module Stash
  describe Harvester do
    describe 'log' do
      it 'logs to stdout in a timestamp-first format' do
        out = StringIO.new
        Harvester.log_device = out
        begin
          msg = "I am a log message"
          Harvester.log.warn(msg)
          logged = out.string
          expect(logged).to include(msg)
          timestamp_str = logged.split[0]
          timestamp = DateTime.parse(timestamp_str)
          expect(timestamp.to_date).to eq(Date.today)
        ensure
          $stdout = orig_stdout
        end
      end
    end
  end
end
