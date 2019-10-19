require 'spec_helper'
require 'stash/download/base'
require 'stash/streamer'
require 'ostruct'
require 'stringio'
require 'active_support/core_ext/time/zones' # required for time
require 'active_support' # required for slice
require 'active_support/core_ext/kernel/reporting'
require 'pathname'
require 'active_support/logger'
require 'byebug'

# a base class for version and file downloads, providing some basic functions
module Stash
  module Download
    describe 'Base' do

      before(:each) do
        # need to hack in Rails.root because our test framework setup sucks
        rails_root = Dir.mktmpdir('rails_root')
        allow(Rails).to receive(:root).and_return(Pathname.new(rails_root))

        @controller_context = 'blah'
        @logger = ActiveSupport::Logger.new(STDOUT)
        allow(@controller_context).to receive(:logger).and_return(@logger)
      end

      it 'initializes with a controller context object' do
        item = Base.new(controller_context: @controller_context)
        expect(item.cc).to eql('blah')
      end

      describe 'send_headers(stream:, header_obj:, filename:)' do
        before(:each) do
          Time.zone = 'Pacific Time (US & Canada)'
          @base = Base.new(controller_context: @controller_context)
          @stream = StringIO.new
          @header_obj = { 'Content-Type' => 'yum/good',
                          'Content-Length' => 10_101,
                          'ETag' => 'kslj34898',
                          'Squirrel-Fun' => 'noggin' }
          @filename = 'num_num.jpg'
          allow(@stream).to receive(:flush).and_return('cats') # flush destroys the output so I can't see if afterward
        end

        it 'adds these headers into the IO stream' do
          @base.send_headers(stream: @stream, header_obj: @header_obj, filename: @filename)
          @stream.rewind
          output = @stream.read
          expect(output).to include("Content-Type: yum/good\r\n")
          expect(output).to include("Content-Length: 10101\r\n")
          expect(output).to include("ETag: kslj34898\r\n")
          expect(output).to include("Content-Disposition: attachment; filename=\"num_num.jpg\"\r\n")
          expect(output).to include("X-Accel-Buffering: no\r\n")
          expect(output).to include("Cache-Control: no-cache\r\n")
          expect(output).to start_with("HTTP/1.1 200 OK\r\n")
        end
      end

      describe 'send_stream(out_stream:, in_stream:)' do
        before(:each) do
          Time.zone = 'Pacific Time (US & Canada)'
          @base = Base.new(controller_context: @controller_context)
          @in_stream = StringIO.new
          @in_stream.puts 'My cat has many fleas. He needs a flea collar.'
          @in_stream.rewind
          @out_stream = StringIO.new
          # maybe I can read these if they are not closed
        end

        it 'what?' do
          @base.send_stream(merritt_stream: @in_stream, user_stream: @out_stream)
          expect(@out_stream.closed?).to eq(true)
          expect(@in_stream.closed?).to eq(true)
          # I couldn't figure out how to get the contents of out stream, even if I prevented it from closing
        end
      end
    end
  end
end
