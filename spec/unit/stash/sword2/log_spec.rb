require 'spec_helper'

module Stash
  module Sword2
    describe 'log' do
      it 'logs to stdout in a timestamp-first format' do
        out = StringIO.new
        Sword2.log_device = out
        begin
          msg = 'I am a log message'
          Sword2.log.warn(msg)
          logged = out.string
          expect(logged).to include(msg)
          timestamp_str = logged.split[0]
          timestamp = DateTime.parse(timestamp_str)
          expect(timestamp.to_date).to eq(Time.now.utc.to_date)
        ensure
          Sword2.log_device = $stdout
        end
      end
    end
  end
end
