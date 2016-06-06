require 'spec_helper'

module Stash
  module Sword
    describe 'log' do
      it 'logs to stdout in a timestamp-first format' do
        out = StringIO.new
        Sword.log_device = out
        begin
          msg = 'I am a log message'
          Sword.log.warn(msg)
          logged = out.string
          expect(logged).to include(msg)
          timestamp_str = logged.split[0]
          timestamp = DateTime.parse(timestamp_str)
          expect(timestamp.to_date).to eq(Time.now.utc.to_date)
        ensure
          Sword.log_device = $stdout
        end
      end
    end
  end
end
