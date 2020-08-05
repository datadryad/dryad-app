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

        # double(Module)
        @my_request = double
        allow(@my_request).to receive(:remote_ip).and_return('127.0.0.1')
        allow(@my_request).to receive(:user_agent).and_return('HorseBrowser 1.1')

        @controller_context = double
        allow(@controller_context).to receive(:request).and_return(@my_request)
        @logger = ActiveSupport::Logger.new(STDOUT)
        allow(@controller_context).to receive(:logger).and_return(@logger)
      end

      it 'initializes with a controller context object' do
        item = Base.new(controller_context: @controller_context)
        expect(item.cc).to eql(@controller_context)
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

        it 'closes the stream after use' do
          @base.send_stream(merritt_stream: @in_stream, user_stream: @out_stream)
          expect(@out_stream.closed?).to eq(true)
        end

        it 'makes the out-stream have the same contents as the in-stream' do
          @base.send_stream(merritt_stream: @in_stream, user_stream: @out_stream)
          expect(@out_stream.string).to eq(@in_stream.string)
        end
      end

      # this takes two copies of the same file.  One is being written to, one is being read from and and output user_stream
      describe 'stream to file methods' do
        before(:each) do
          Time.zone = 'Pacific Time (US & Canada)'
          @base = Base.new(controller_context: @controller_context)

          @write_file = Tempfile.create('dl_file', Rails.root).binmode
          @write_file.flock(::File::LOCK_NB | ::File::LOCK_SH)
          @write_file.sync = true

          @read_file = ::File.open(@write_file, 'r')

          @user_stream = StringIO.new
        end

        it "(stream_from_file) doesn't read past the end or close if writing to the file is slower than reading it" do
          contents = (0...50).map { ('a'..'z').to_a[rand(26)] }.join # random string, import Faker sometime in here

          Thread.new do
            sleep 3
            @write_file.write(contents)
            @write_file.close
          end

          # this should block until it has streamed to 'user' completely (ie, @user_stream)
          @base.stream_from_file(read_file: @read_file, write_file: @write_file, user_stream: @user_stream)

          expect(@user_stream.string).to eql(::File.open(@write_file).read)
        end

        it '(save_to_file) saves contents from a stream to a file (in chunks)' do
          contents = StringIO.new((0...50).map { ('a'..'z').to_a[rand(26)] }.join)
          @base.save_to_file(merritt_stream: contents, write_file: @write_file)
          expect(@write_file.closed?).to eq(true)
          expect(::File.open(@write_file).read).to eq(contents.string)
        end
      end
    end
  end
end
