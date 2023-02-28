module Stash
  module Deposit
    describe LogUtils do

      attr_reader :log_utils
      attr_reader :rails_env
      attr_reader :log_io

      before(:all) { @rails_env = ENV.fetch('RAILS_ENV', nil) }
      after(:all) { ENV['RAILS_ENV'] = rails_env }

      before(:each) do
        @log_io = StringIO.new
        @log_utils = Class.new { include LogUtils }.new
        @log_utils.instance_variable_set(:@logger, LogUtils.create_default_logger(@log_io, log_utils.level))
      end

      def log_str
        @log_io.string
      end

      it 'sets the log level based on $RAILS_ENV' do
        expected = {
          'test' => Logger::DEBUG,
          'development' => Logger::INFO,
          'stage' => Logger::WARN,
          'production' => Logger::WARN
        }
        expected.each do |env, lvl|
          ENV['RAILS_ENV'] = env
          expect(Class.new { include LogUtils }.new.level).to eq(lvl)
        end
        ENV['RAILS_ENV'] = 'test'  # otherwise database cleaner errors, also shouldn't change the rails environment after test
      end

      it 'logs an error response' do
        code = 404
        body = 'Your princess is in another castle'
        headers = { 'Location' => 'http://example.org' }
        message = 'I am the message'

        response = instance_double(RestClient::Response)
        expect(response).to receive(:code) { code }
        expect(response).to receive(:headers) { headers }
        expect(response).to receive(:body) { body }

        error = RestClient::ExceptionWithResponse.new(response, 999)
        error.message = message

        log_utils.log_error(error)
        expect(log_str).to include(code.to_s)
        expect(log_str).to include(body)
        headers.each do |k, v|
          expect(log_str).to include("#{k}: #{v}")
        end
        expect(log_str).to include(message)
      end

      it 'logs an error with a nil response' do
        message = 'I am the message'
        error = RestClient::ExceptionWithResponse.new(nil, 999)
        error.message = message
        log_utils.log_error(error)
        expect(log_str).to include(message)
      end

      it 'logs an error with a backtrace' do
        backtrace = nil
        begin
          raise RestClient::ExceptionWithResponse.new(nil, 999)
        rescue StandardError => e
          backtrace = e.backtrace
          log_utils.log_error(e)
        end
        expect(log_str).to include(backtrace.join("\n"))
      end
    end
  end
end
