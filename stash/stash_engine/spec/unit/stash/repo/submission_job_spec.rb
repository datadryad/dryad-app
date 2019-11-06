require 'spec_helper'
require 'concurrent'

module Stash
  module Repo
    describe SubmissionJob do
      attr_reader :job
      attr_reader :logger

      before(:each) do
        @job = SubmissionJob.new(resource_id: 17)

        @logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(logger)

        immediate_executor = Concurrent::ImmediateExecutor.new
        allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)

        pool = double(ActiveRecord::ConnectionAdapters::ConnectionPool)
        allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool)
        allow(pool).to receive(:with_connection).and_yield
      end

      after(:each) do
        allow(Concurrent).to receive(:global_io_executor).and_call_original
        allow(Rails).to receive(:logger).and_call_original
      end

      describe :submit! do
        it 'is abstract' do
          expect { job.submit! }.to raise_error(NoMethodError)
        end
      end

      describe :description do
        it 'is abstract' do
          expect { job.description }.to raise_error(NoMethodError)
        end
      end

      describe :submit_async do
        it 'delegates to :submit!, asynchronously' do
          result = SubmissionResult.new(resource_id: 17, request_desc: 'test', message: 'whee!')
          job.define_singleton_method(:submit!) { result }
          promise = job.submit_async(executor: Concurrent::ImmediateExecutor.new)
          raise promise.reason if promise.reason
          expect(promise.value).to be(result)
        end

        it 'handles errors' do
          job.define_singleton_method(:submit!) { raise Errno::ENOENT }
          promise = job.submit_async(executor: Concurrent::ImmediateExecutor.new)
          expect(promise.reason).to be_an(Errno::ENOENT)
        end
      end

      describe :log do
        it 'returns the Rails logger' do
          expect(job.log).to be(logger)
        end
      end
    end
  end
end
