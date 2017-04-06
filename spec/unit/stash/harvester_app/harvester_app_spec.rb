require 'spec_helper'
require 'stash/harvester_app'

module Stash
  describe HarvesterApp do
    describe '#constants' do
      it "includes all constants from #{Harvester}" do
        Stash::Harvester.constants.each do |c|
          expect(HarvesterApp.const_get(c)).to be(Harvester.const_get(c))
        end
      end
    end

    describe '#log' do
      it 'logs to stdout in a timestamp-first format' do
        out = StringIO.new
        HarvesterApp.log_device = out
        begin
          msg = 'I am a log message'
          HarvesterApp.log.warn(msg)
          logged = out.string
          expect(logged).to include(msg)
          timestamp_str = logged.split[0]
          timestamp = DateTime.parse(timestamp_str)
          expect(timestamp.to_date).to eq(Time.now.utc.to_date)
        ensure
          HarvesterApp.log_device = $stdout
        end
      end
    end
  end
end
